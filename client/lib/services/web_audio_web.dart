// Web implementation of browser audio/TTS/STT using JS interop
import 'dart:js_interop';

@JS('startSpeechRecognition')
external bool startSpeechRecognitionJS(JSFunction callback, JSFunction endCallback);

@JS('stopSpeechRecognition')
external void stopSpeechRecognitionJS();

@JS('playBase64Audio')
external void playBase64AudioJS(JSString audioBase64);

@JS('speakTextWithBrowserTTS')
external void speakTextWithBrowserTTSJS(JSString text);

void playWebAudio(String? base64Wav, String text) {
  try {
    if (base64Wav != null && base64Wav.isNotEmpty) {
      playBase64AudioJS(base64Wav.toJS);
    } else {
      speakTextWithBrowserTTSJS(text.toJS);
    }
  } catch (_) {}
}

bool startWebSpeechRecognition(
  void Function(String text) onText,
  void Function() onEnd,
) {
  try {
    final callback = ((JSString text) {
      onText(text.toDart);
    }).toJS;

    final endCallback = (() {
      onEnd();
    }).toJS;

    return startSpeechRecognitionJS(callback, endCallback);
  } catch (_) {
    return false;
  }
}

void stopWebSpeechRecognition() {
  try {
    stopSpeechRecognitionJS();
  } catch (_) {}
}
