import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _textRecognizer;

  OcrService()
      : _textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);

  Future<String> extractTextFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    try {
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        throw Exception('이미지에서 텍스트를 찾을 수 없어. 다른 이미지를 선택해줘!');
      }

      return recognizedText.text;
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
