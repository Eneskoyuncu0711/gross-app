// lib/services/ai_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  // Modeli bir kere oluşturup hafızada tutalım
  late final GenerativeModel _model;

  AiService() {
    // .env içindeki şifremizi güvenle çekiyoruz
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null) {
      throw Exception(
        'GEMINI_API_KEY bulunamadı! Lütfen .env dosyasını kontrol et.',
      );
    }

    _model = GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);
  }

  // Finansal Raporu Yorumlayacak Metot
  Future<String> getFinancialAdvice(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ??
          "Patron, verileri analiz edemedim. Lütfen tekrar dene.";
    } catch (e) {
      return "Bir hata oluştu: $e \nİnternet bağlantınızı kontrol edin.";
    }
  }
}
