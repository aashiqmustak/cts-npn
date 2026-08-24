// Stub implementation for non-web platforms

void playWebAudio(String? base64Wav, String text) {}

bool startWebSpeechRecognition(
  void Function(String text) onText,
  void Function() onEnd,
) => false;

void stopWebSpeechRecognition() {}
