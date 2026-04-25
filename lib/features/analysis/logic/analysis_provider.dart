import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loan_lens/features/analysis/logic/analysis_service.dart';
import 'package:loan_lens/features/analysis/logic/analysis_models.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

enum AnalysisStatus { idle, picking, loading, success, error }

/// Thrown when there is a configuration problem (e.g. missing API key).
/// These should NOT trigger offline fallback.
class _ConfigException implements Exception {
  final String message;
  _ConfigException(this.message);
  @override String toString() => message;
}

class AnalysisProvider with ChangeNotifier {
  final AnalysisService _service = AnalysisService();
  final FlutterTts _flutterTts = FlutterTts();
  
  // SECURE PROXY: Key is managed by Cloudflare Secret, never sent to the client.
  final String _proxyUrl = 'https://loanlens-proxy.shubhijb21.workers.dev';
  
  AnalysisStatus _status = AnalysisStatus.idle;
  String? _error;
  String _debugMessage = ''; // Live UI feedback
  
  String? _parsedResult;
  List<Finding> _findings = [];
  double _score = 1.0;
  int _riskScore = 10;
  String _lastTargetLanguage = 'English'; 
  
  Map<String, String> _uiTranslations = {
      'safe_label': 'Safe',
      'safe_msg': 'Safe to proceed',
      'mod_label': 'Moderate Risk',
      'mod_msg': 'Proceed with caution',
      'high_label': 'High Risk / Predatory',
      'high_msg': 'Avoid this loan',
      'hdr_vio': 'RBI VIOLATIONS',
      'hdr_bias': 'ALGORITHMIC BIAS',
      'hdr_action': 'ACTION PLAN',
      'hdr_pred': 'HIGH RISK / PREDATORY',
      'hdr_scorecard': 'Fairness Scorecard',
      'hdr_detailed': 'Detailed Findings',
      'btn_scan': 'Scan Another Document',
      'btn_rbi': 'File RBI Complaint',
      'lbl_detected': 'Detected:',
  };

  AnalysisStatus get status => _status;
  String? get error => _error;
  String? get parsedResult => _parsedResult;
  List<Finding> get findings => _findings;
  double get score => _score;
  int get riskScore => _riskScore;
  Map<String, String> get uiTranslations => _uiTranslations;
  bool get isPredatory => _riskScore <= 4;
  String get debugMessage => _debugMessage;

  Future<void> analyzeVoiceInput(String text, String targetLanguage, {bool userOptIn = false, String appName = 'Unknown'}) async {
    _status = AnalysisStatus.loading;
    _error = null;
    _debugMessage = 'Guardian Analysis in Progress...';
    notifyListeners();

    _lastTargetLanguage = targetLanguage;
    _lastInputType = 'voice';
    _lastInputText = text;
    _lastAppName = appName;
    _lastUserOptIn = userOptIn;

    try {
      _debugMessage = 'Connecting to Secure Guardian Proxy...';
      notifyListeners();

      final responseText = await _callProxy(
        prompt: "Analyze this voice transcription for loan fairness: \"$text\"",
        targetLanguage: targetLanguage,
      );

      await _processResponse(responseText, appName, targetLanguage, userOptIn);
    } catch (e, stack) {
      if (e is _ConfigException) {
        _handleError(e, stack);
        return;
      }
      
      final String errorMessage = _isNetworkError(e) 
          ? 'Guardian Unreachable. Please check your internet connection and try again.'
          : 'Analysis failed: ${e.toString()}';
      
      _handleError(errorMessage, stack);
    }
  }


  Future<void> analyzeLoanDocument(ImageSource source, String targetLanguage, {bool userOptIn = false, String appName = 'Unknown'}) async {
    _status = AnalysisStatus.picking;
    _error = null;
    _debugMessage = 'Step 1: Opening Camera/Gallery...';
    notifyListeners();

    _lastTargetLanguage = targetLanguage;
    _lastInputType = 'document';
    _lastAppName = appName;
    _lastUserOptIn = userOptIn;

    try {
      final image = await _service.pickImage(source);
      if (image == null) {
        _status = AnalysisStatus.idle;
        _debugMessage = '';
        notifyListeners();
        return;
      }
      _lastInputImage = image;

      _debugMessage = 'Processing Image...';
      notifyListeners();

      _status = AnalysisStatus.loading;
      notifyListeners();

      final rawBytes = await image.readAsBytes();
      final dataPart = DataPart('image/jpeg', rawBytes);

      _debugMessage = 'Step 3: Initializing AI Model...';
      notifyListeners();

      _debugMessage = 'Analyzing via Secure Guardian Proxy...';
      notifyListeners();
      
      try {
        final responseText = await _callProxy(
          prompt: "Perform a full Guardian Audit on this loan document.",
          targetLanguage: targetLanguage,
          imageBytes: rawBytes,
        );
        await _processResponse(responseText, appName, targetLanguage, userOptIn);
      } catch (e, stack) {
        if (e is _ConfigException) rethrow;

        final String errorMessage = _isNetworkError(e) 
            ? 'Guardian Unreachable. Please check your internet connection and try again.'
            : 'Analysis failed: ${e.toString()}';
        
        _handleError(errorMessage, stack);
      }

    } catch (e, stack) {
      _handleError(e, stack);
    }
  }

  bool _isNetworkError(dynamic e) {
    final str = e.toString().toLowerCase();
    return str.contains('socketexception') || 
           str.contains('clientexception') || 
           str.contains('timeout') || 
           str.contains('network');
  }

  // State for Retrying
  String? _lastInputType;
  String? _lastInputText;
  XFile? _lastInputImage;
  String? _lastAppName;
  bool? _lastUserOptIn;

  Future<void> retryLastAnalysis() async {
    if (_lastInputType == 'voice' && _lastInputText != null) {
      await analyzeVoiceInput(_lastInputText!, _lastTargetLanguage, userOptIn: _lastUserOptIn ?? false, appName: _lastAppName ?? 'Unknown');
    } else if (_lastInputType == 'document' && _lastInputImage != null) {
      _status = AnalysisStatus.loading;
      _error = null;
      _debugMessage = 'Guardian Analysis in Progress...';
      notifyListeners();

      try {
        final rawBytes = await _lastInputImage!.readAsBytes();
        final responseText = await _callProxy(
          prompt: "Analyze this loan document.",
          targetLanguage: _lastTargetLanguage,
          imageBytes: rawBytes,
        );
        await _processResponse(responseText, _lastAppName ?? 'Unknown', _lastTargetLanguage, _lastUserOptIn ?? false);
      } catch (e, stack) {
        final String errorMessage = _isNetworkError(e) 
            ? 'Guardian Unreachable. Please check your internet connection.'
            : 'Retry failed: ${e.toString()}';
        _handleError(errorMessage, stack);
      }
    }
  }

  Future<String> _callProxy({
    required String prompt,
    required String targetLanguage,
    List<int>? imageBytes,
  }) async {
    final Map<String, dynamic> body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": prompt},
            if (imageBytes != null)
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": base64Encode(imageBytes)
                }
              }
          ]
        }
      ],
      // System instructions are now passed in the body since we aren't using the SDK's systemInstruction param
      "systemInstruction": {
        "parts": [
          {
            "text": "Role: You are the LoanLens Guardian, an expert in Indian Digital Lending Compliance (RBI 2025/2026) and Fairness Analysis. "
                    "Objective: Analyze loan offers to detect Predatory practices, RBI violations, and Algorithmic bias. "
                    "Scoring Logic: Score 8-10 (Safe), 5-7 (Moderate), 1-4 (Dangerous). "
                    "CRITICAL: If APR > 45%, Illegal Permissions (Contacts/Photos/Media) exist, or KFS is missing with high risk, then set is_predatory = true and risk_score MUST be 1-4. NEVER assign score > 7 if any violation exists. "
                    "Language Rule: ALL user-facing text (bias_report, verdict_vernacular, next_steps, detected_violations) MUST be in $targetLanguage. Do NOT mix languages. "
                    "Verdict Rule: The `verdict_vernacular` MUST adopt an empathetic but urgent tone. If predatory, it must state exactly how high the interest rate is compared to the legal ceiling, explicitly mention 'Here is the RBI complaint portal link', and provide 3 regulated alternatives they qualify for (e.g., Mudra, PM SVANidhi). "
                    "Analysis Rules: "
                    "1. Interest Rate: APR > 45% (Predatory), 36-45% (High Risk), < 24% (Safe). "
                    "2. Permissions: Access to Contacts, Photos, Media is ILLEGAL. "
                    "3. KFS: Missing Key Fact Statement is a Violation. "
                    "4. Algorithmic Bias & Proxy Detection: Actively scan the text for demographic proxy signals. Explicitly evaluate and state if this interest rate or penalty structure is disproportionately hostile compared to a baseline offer given to a salaried urban professional for the identical principal amount. If demographic targeting is detected based on language, region, or employment type, flag it severely. Keep explanation SHORT and in $targetLanguage. "
                    "Respond strictly in valid JSON format. Ensure all text inside JSON values is properly escaped. "
                    "Output Format: { \"is_predatory\": boolean, \"risk_score\": number (1-10), \"critical_violations\": [\"short list translated to $targetLanguage\"], \"minor_warnings\": [\"short list translated to $targetLanguage\"], \"bias_type\": \"e.g. Demographic, Geographic, Gender, None\", \"interest_rate_deviation\": \"e.g. +15%\", \"bias_report\": \"string in $targetLanguage\", \"verdict_vernacular\": \"string in $targetLanguage\", \"next_steps\": \"string in $targetLanguage\", \"ui_translations\": {\"safe_label\":\"Safe\", \"safe_msg\":\"Safe to proceed\", \"mod_label\":\"Moderate Risk\", \"mod_msg\":\"Proceed with caution\", \"high_label\":\"High Risk / Predatory\", \"high_msg\":\"Avoid this loan\", \"hdr_vio\":\"RBI VIOLATIONS\", \"hdr_warn\":\"MINOR WARNINGS\", \"hdr_bias\":\"ALGORITHMIC BIAS\", \"hdr_action\":\"ACTION PLAN\", \"hdr_pred\":\"HIGH RISK / PREDATORY\", \"hdr_scorecard\":\"Fairness Scorecard\", \"hdr_detailed\":\"Detailed Findings\", \"btn_scan\":\"Scan Another Document\", \"btn_rbi\":\"File RBI Complaint\", \"rbi_desc\":\"This loan shows signs of predatory practices. You have the right to report this to the regulator.\", \"btn_action\":\"TAKE ACTION NOW\", \"lbl_detected\":\"Detected:\", \"lbl_fairness\":\"Fairness\"} (Translate ALL these string values AND arrays to $targetLanguage) }"
          }
        ]
      },
      "generationConfig": {
        "responseMimeType": "application/json"
      }
    };

    final response = await http.post(
      Uri.parse(_proxyUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw Exception('Proxy Error (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    // The Gemini API response structure: { candidates: [ { content: { parts: [ { text: "..." } ] } } ] }
    final String resultText = decoded['candidates'][0]['content']['parts'][0]['text'];
    return resultText;
  }

  Future<void> _processResponse(String? jsonOutput, String appName, String targetLanguage, bool userOptIn) async {
    debugPrint('Gemini Response: $jsonOutput');
    if (jsonOutput == null || jsonOutput.isEmpty) {
      throw Exception('Received an empty response from the AI model.');
    }

    // CLEANER: Remove markdown backticks if present
    String cleanJson = jsonOutput.trim();
    if (cleanJson.startsWith('```')) {
      cleanJson = cleanJson.replaceAll(RegExp(r'^```json\s*|```$'), '').trim();
    }

    final Map<String, dynamic> parsedData = jsonDecode(cleanJson);
    
    int riskScore = parsedData['risk_score'] ?? 10;
    bool isPredatory = parsedData['is_predatory'] ?? false;
    List criticalViolations = parsedData['critical_violations'] ?? [];
    List minorWarnings = parsedData['minor_warnings'] ?? [];

    if (isPredatory || criticalViolations.isNotEmpty) {
      riskScore = riskScore.clamp(1, 4);
    } else if (minorWarnings.isNotEmpty) {
      riskScore = riskScore.clamp(5, 7);
    } else {
      riskScore = riskScore.clamp(8, 10);
    }

    parsedData['risk_score'] = riskScore;
    _riskScore = riskScore;
    _score = (riskScore / 10.0).clamp(0.0, 1.0);

    final Map<String, dynamic> translationsRaw = parsedData['ui_translations'] ?? {};
    _uiTranslations = {
      'safe_label': translationsRaw['safe_label']?.toString() ?? 'Safe',
      'safe_msg': translationsRaw['safe_msg']?.toString() ?? 'Safe to proceed',
      'mod_label': translationsRaw['mod_label']?.toString() ?? 'Moderate Risk',
      'mod_msg': translationsRaw['mod_msg']?.toString() ?? 'Proceed with caution',
      'high_label': translationsRaw['high_label']?.toString() ?? 'High Risk / Predatory',
      'high_msg': translationsRaw['high_msg']?.toString() ?? 'Avoid this loan',
      'hdr_vio': translationsRaw['hdr_vio']?.toString() ?? 'RBI VIOLATIONS',
      'hdr_warn': translationsRaw['hdr_warn']?.toString() ?? 'MINOR WARNINGS',
      'hdr_bias': translationsRaw['hdr_bias']?.toString() ?? 'ALGORITHMIC BIAS',
      'hdr_action': translationsRaw['hdr_action']?.toString() ?? 'ACTION PLAN',
      'hdr_pred': translationsRaw['hdr_pred']?.toString() ?? 'HIGH RISK / PREDATORY',
      'hdr_scorecard': translationsRaw['hdr_scorecard']?.toString() ?? 'Fairness Scorecard',
      'hdr_detailed': translationsRaw['hdr_detailed']?.toString() ?? 'Detailed Findings',
      'btn_scan': translationsRaw['btn_scan']?.toString() ?? 'Scan Another Document',
      'btn_rbi': translationsRaw['btn_rbi']?.toString() ?? 'File RBI Complaint',
      'lbl_detected': translationsRaw['lbl_detected']?.toString() ?? 'Detected:',
      'lbl_fairness': translationsRaw['lbl_fairness']?.toString() ?? 'Fairness',
    };

    _findings = _mapGuardianJsonToFindings(parsedData);

    if (userOptIn) {
      try {
        await FirebaseFirestore.instance.collection('scans').add({
          'timestamp': FieldValue.serverTimestamp(),
          'appName': appName,
          'risk_score': riskScore,
          'bias_type': parsedData['bias_type'] ?? 'Unknown',
          'interest_rate_deviation': parsedData['interest_rate_deviation'] ?? 'Unknown',
        });
      } catch (e) {
        debugPrint('Firestore Write Error: $e');
      }
    }

    _parsedResult = jsonEncode(parsedData);
    _status = AnalysisStatus.success;
    _debugMessage = '';
    notifyListeners();
    
    // Autoplay TTS
    await speakCurrentVerdict(targetLanguage);
  }

  void _handleError(dynamic e, StackTrace stack) {
    debugPrint('CRITICAL ERROR during analysis: $e');
    debugPrint('STACK TRACE: $stack');
    _error = 'Failed to analyze: $e';
    _status = AnalysisStatus.error;
    notifyListeners();
  }

  List<Finding> _mapGuardianJsonToFindings(Map<String, dynamic> parsedData) {
    List<Finding> mappedFindings = [];
    
    final bool isPredatory = parsedData['is_predatory'] ?? false;
    final int riskScore = parsedData['risk_score'] ?? 0;

    if (isPredatory || riskScore <= 4) {
      mappedFindings.add(Finding(
        term: _uiTranslations['hdr_pred'] ?? 'HIGH RISK / PREDATORY',
        description: parsedData['verdict_vernacular'] ?? 'Serious RBI compliance violation detected.',
        level: FairnessLevel.danger,
      ));
    }

    final List<dynamic>? criticalViolations = parsedData['critical_violations'];
    if (criticalViolations != null && criticalViolations.isNotEmpty) {
      mappedFindings.add(Finding(
        term: _uiTranslations['hdr_vio'] ?? 'RBI VIOLATIONS',
        description: '${_uiTranslations['lbl_detected'] ?? 'Detected:'} ${criticalViolations.join(', ')}',
        level: FairnessLevel.danger,
      ));
    }

    final List<dynamic>? minorWarnings = parsedData['minor_warnings'];
    if (minorWarnings != null && minorWarnings.isNotEmpty) {
      mappedFindings.add(Finding(
        term: _uiTranslations['hdr_warn'] ?? 'MINOR WARNINGS',
        description: '${_uiTranslations['lbl_detected'] ?? 'Detected:'} ${minorWarnings.join(', ')}',
        level: FairnessLevel.warning,
      ));
    }

    final String bias = parsedData['bias_report'] ?? '';
    if (bias.isNotEmpty && bias.toLowerCase() != 'none') {
      mappedFindings.add(Finding(
        term: _uiTranslations['hdr_bias'] ?? 'ALGORITHMIC BIAS',
        description: bias,
        level: FairnessLevel.warning,
      ));
    }

    final String nextSteps = parsedData['next_steps'] ?? '';
    if (nextSteps.isNotEmpty) {
      mappedFindings.add(Finding(
        term: _uiTranslations['hdr_action'] ?? 'ACTION PLAN',
        description: nextSteps,
        level: FairnessLevel.warning,
      ));
    }

    return mappedFindings;
  }

  Future<void> speakCurrentVerdict(String languageName) async {
    if (_parsedResult == null) return;
    try {
      final Map<String, dynamic> data = jsonDecode(_parsedResult!);
      String textToSpeak = data['verdict_vernacular'] ?? 'Analysis complete.';
      
      String langCode = 'en-IN';
      switch(languageName) {
        case 'Hindi': langCode = 'hi-IN'; break;
        case 'Marathi': langCode = 'mr-IN'; break;
        case 'Tamil': langCode = 'ta-IN'; break;
        case 'Telugu': langCode = 'te-IN'; break;
        case 'Bengali': langCode = 'bn-IN'; break;
        case 'Gujarati': langCode = 'gu-IN'; break;
        case 'Kannada': langCode = 'kn-IN'; break;
        case 'Malayalam': langCode = 'ml-IN'; break;
        case 'Punjabi': langCode = 'pa-IN'; break;
      }
      await _flutterTts.setLanguage(langCode);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.speak(textToSpeak);
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }

  void reset() {
    stopTTS();
    _status = AnalysisStatus.idle;
    _error = null;
    _parsedResult = null;
    _findings = [];
    _score = 1.0;
    notifyListeners();
  }

  Future<void> stopTTS() async {
    await _flutterTts.stop();
  }

  Future<void> replayVerdict() async {
    await stopTTS(); // Stop existing before starting fresh
    await speakCurrentVerdict(_lastTargetLanguage);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
