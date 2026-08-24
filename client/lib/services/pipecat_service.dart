import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'api_config.dart';

enum PipecatState {
  disconnected,
  connecting,
  connected,
  failed,
}

class PipecatTranscript {
  final String sender;
  final String text;
  final String time;

  PipecatTranscript({
    required this.sender,
    required this.text,
    required this.time,
  });
}

class PipecatService extends ChangeNotifier {
  PipecatState _state = PipecatState.disconnected;
  PipecatState get state => _state;
  bool get isConnected => _state == PipecatState.connected;

  final List<PipecatTranscript> _transcripts = [];
  List<PipecatTranscript> get transcripts => _transcripts;

  String _latestSpeechText = '';
  String get latestSpeechText => _latestSpeechText;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  RTCDataChannel? _dataChannel;
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  bool _initialized = false;
  String? _sessionId;
  String? _serverPcId;

  // Getter for dynamically determining API url based on page host
  String get apiBaseUrl => ApiConfig.instance.baseUrl;

  Future<void> initialize() async {
    if (_initialized) return;
    await remoteRenderer.initialize();
    _initialized = true;
  }

  void clearTranscripts() {
    _transcripts.clear();
    _latestSpeechText = '';
    notifyListeners();
  }

  Future<void> connect() async {
    if (_state != PipecatState.disconnected) return;

    _state = PipecatState.connecting;
    notifyListeners();

    try {
      await initialize();

      // Request microphone permission explicitly
      if (!kIsWeb) {
        final status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          throw Exception('Microphone permission denied');
        }
      }

      // 1. Get user media (microphone only)
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

      // 2. Create peer connection configuration
      final Map<String, dynamic> configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
        'sdpSemantics': 'unified-plan',
      };

      _peerConnection = await createPeerConnection(configuration);

      // Add local audio tracks to the peer connection
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      // Handle remote tracks (audio stream from bot)
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.track.kind == 'audio') {
          // Play the audio stream using remote renderer
          remoteRenderer.srcObject = event.streams[0];
          notifyListeners();
        }
      };

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('WebRTC Connection State changed: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _state = PipecatState.connected;
          notifyListeners();
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          disconnect();
        }
      };

      // 3. Register Data Channel handlers (for both client and server created channels)
      void setupChannelHandlers(RTCDataChannel channel) {
        channel.onMessage = (RTCDataChannelMessage message) {
          try {
            final raw = message.text;
            if (raw.isEmpty) return;

            Map<String, dynamic>? data;
            try {
              data = json.decode(raw) as Map<String, dynamic>?;
            } catch (_) {
              try {
                final unescaped = raw.replaceAll(r'\"', '"').replaceAll(r'\\', '');
                data = json.decode(unescaped) as Map<String, dynamic>?;
              } catch (_) {
                data = null;
              }
            }

            // Drop unparseable raw JSON strings
            if (data == null && (raw.trim().startsWith('{') || raw.trim().startsWith('"{') || raw.trim().startsWith(r'\"{\'))) {
              return;
            }

            String text = '';
            String sender = 'agent';

            if (data != null) {
              final type = data['type']?.toString() ?? '';
              final innerData = data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : null;

              if (type == 'user-transcription' || type == 'user_transcript' || type == 'user-llm-text' || (data['sender']?.toString() == 'user')) {
                sender = 'user';
                text = innerData != null ? (innerData['text']?.toString() ?? '') : (data['text']?.toString() ?? '');
              } else if (type == 'bot-transcription' || type == 'bot-tts-text' || type == 'bot_transcript' || (data['sender']?.toString() == 'agent')) {
                sender = 'agent';
                text = innerData != null ? (innerData['text']?.toString() ?? '') : (data['text']?.toString() ?? '');
              } else if (type == 'bot-llm-text') {
                // Ignore streaming token fragments from LLM
                return;
              } else {
                text = data['text']?.toString() ?? data['message']?.toString() ?? '';
                sender = data['sender']?.toString() ?? (type == 'user' ? 'user' : 'agent');
              }
            } else {
              text = raw;
            }

            final cleanText = text.trim();
            if (cleanText.isEmpty) return;

            if (sender == 'user') {
              // Update latest transcribed text for the input box
              _latestSpeechText = cleanText;
              notifyListeners();
              return;
            }

            // Ignore tiny single-word fragments for assistant bubbles
            if (cleanText.split(' ').length < 2 && cleanText.length < 15) {
              return;
            }

            // Deduplicate identical consecutive messages
            if (_transcripts.isNotEmpty &&
                _transcripts.first.sender == sender &&
                _transcripts.first.text == cleanText) {
              return;
            }

            final now = DateTime.now();
            final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
            _transcripts.insert(0, PipecatTranscript(
              sender: sender,
              text: cleanText,
              time: timeStr,
            ));
            notifyListeners();
          } catch (e) {
            debugPrint('[Pipecat] Error parsing data channel message: $e');
          }
        };
      }

      // Handle server-created data channels
      _peerConnection!.onDataChannel = (RTCDataChannel channel) {
        debugPrint('[Pipecat] Incoming server DataChannel: ${channel.label}');
        _dataChannel = channel;
        setupChannelHandlers(channel);
      };

      // Create client data channel
      final RTCDataChannelInit init = RTCDataChannelInit()..ordered = true;
      _dataChannel = await _peerConnection!.createDataChannel('pipecat', init);
      setupChannelHandlers(_dataChannel!);

      // 4. Start session and negotiate offer
      final baseUrl = apiBaseUrl;
      
      // Step A: POST /start to get session ID
      final startResponse = await http.post(
        Uri.parse('$baseUrl/start'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'transport': 'webrtc'}),
      );

      if (startResponse.statusCode != 200) {
        throw Exception('Failed to start session: ${startResponse.body}');
      }

      final startData = json.decode(startResponse.body);
      _sessionId = startData['sessionId'];
      if (_sessionId == null) {
        throw Exception('No sessionId returned from server');
      }

      // Step B: Create Local SDP Offer
      final RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      });
      await _peerConnection!.setLocalDescription(offer);

      final List<RTCIceCandidate> bufferedCandidates = [];
      bool offerSent = false;

      // Handle candidate gathering trickling
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
        if (!offerSent) {
          bufferedCandidates.add(candidate);
          return;
        }
        if (_sessionId == null || _serverPcId == null) return;
        try {
          await http.patch(
            Uri.parse('$baseUrl/sessions/$_sessionId/api/offer'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'pc_id': _serverPcId,
              'candidates': [
                {
                  'candidate': candidate.candidate,
                  'sdp_mid': candidate.sdpMid,
                  'sdp_mline_index': candidate.sdpMLineIndex,
                }
              ]
            }),
          );
        } catch (e) {
          debugPrint('Error sending ICE candidate: $e');
        }
      };

      // Step C: Send SDP offer to /sessions/{sessionId}/api/offer
      final offerResponse = await http.post(
        Uri.parse('$baseUrl/sessions/$_sessionId/api/offer'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sdp': offer.sdp,
          'type': offer.type,
          'pc_id': _sessionId,
        }),
      );

      if (offerResponse.statusCode != 200) {
        throw Exception('Failed to negotiate WebRTC offer: ${offerResponse.body}');
      }

      final offerData = json.decode(offerResponse.body);
      _serverPcId = offerData['pc_id'] ?? _sessionId;

      offerSent = true;
      for (final candidate in bufferedCandidates) {
        if (_sessionId == null || _serverPcId == null) break;
        try {
          await http.patch(
            Uri.parse('$baseUrl/sessions/$_sessionId/api/offer'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'pc_id': _serverPcId,
              'candidates': [
                {
                  'candidate': candidate.candidate,
                  'sdp_mid': candidate.sdpMid,
                  'sdp_mline_index': candidate.sdpMLineIndex,
                }
              ]
            }),
          );
        } catch (e) {
          debugPrint('Error sending buffered ICE candidate: $e');
        }
      }
      bufferedCandidates.clear();

      final String? answerSdp = offerData['sdp'];
      if (answerSdp == null) {
        throw Exception('No answer SDP returned from server');
      }

      // Step D: Set Remote Description
      final RTCSessionDescription answer = RTCSessionDescription(answerSdp, 'answer');
      await _peerConnection!.setRemoteDescription(answer);

    } catch (e) {
      debugPrint('Error establishing WebRTC connection: $e');
      _state = PipecatState.failed;
      notifyListeners();
      disconnect();
    }
  }

  Future<void> disconnect() async {
    if (_state == PipecatState.disconnected) return;

    _sessionId = null;
    _serverPcId = null;

    try {
      await _dataChannel?.close();
    } catch (_) {}
    _dataChannel = null;

    try {
      _localStream?.getTracks().forEach((track) {
        track.stop();
      });
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;

    try {
      await _peerConnection?.close();
      await _peerConnection?.dispose();
    } catch (_) {}
    _peerConnection = null;

    remoteRenderer.srcObject = null;
    _state = PipecatState.disconnected;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    remoteRenderer.dispose();
    super.dispose();
  }
}
