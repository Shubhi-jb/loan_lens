import 'package:image_picker/image_picker.dart';

/// Service for picking images. 
/// Local OCR (ML Kit) is disabled for web compatibility. 
/// Gemini AI handles OCR and analysis directly from the image bytes.
class AnalysisService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    return image;
  }

  void dispose() {
    // No-op
  }
}
