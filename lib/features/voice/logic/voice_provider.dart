import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<bool> initialize({Function(double)? onSoundLevelChange}) async {
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('Speech Status: $status'),
      onError: (error) => debugPrint('Speech Error: $error'),
    );
    return available;
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function(double)? onSoundLevelChange,
    String? localeId,
  }) async {
    // Ensure permission
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      await Permission.microphone.request();
    }

    if (await Permission.microphone.isGranted) {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
        onSoundLevelChange: (level) {
          if (onSoundLevelChange != null) {
            onSoundLevelChange(level);
          }
        },
        localeId: localeId,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 60), // Increased from 30s
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: false, // Don't stop on minor network jitters
      );
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}

class VoiceProvider with ChangeNotifier {
  final VoiceService _voiceService = VoiceService();
  String _lastWords = '';
  bool _isListening = false;
  double _soundLevel = 0.0;
  String? _error;

  String get lastWords => _lastWords;
  bool get isListening => _isListening;
  double get soundLevel => _soundLevel;
  String? get error => _error;

  Future<void> startRecording(String localeId) async {
    _lastWords = '';
    _error = null;
    
    bool initialized = await _voiceService.initialize();
    if (initialized) {
      _isListening = true;
      notifyListeners();

      await _voiceService.startListening(
        localeId: localeId,
        onResult: (words) {
          _lastWords = words;
          notifyListeners();
        },
        onSoundLevelChange: (level) {
          // Normalize sound level: speech_to_text levels are typically -2 to 10
          _soundLevel = (level + 2) / 12.0;
          _soundLevel = _soundLevel.clamp(0.0, 1.0);
          notifyListeners();
        },
      );
    } else {
      _error = 'Speech recognition not available on this device.';
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    await _voiceService.stopListening();
    _isListening = false;
    notifyListeners();
  }
}
