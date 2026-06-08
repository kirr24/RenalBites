import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class KaloriApi {
  static const String _baseUrl =
      'https://api.kalori-api.my/api/v1/foods/search';

  double extractServingGrams(String serving) {
    final regex = RegExp(r'(\d+)\s*g');
    final match = regex.firstMatch(serving);

    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 100.0;
    }

    return 100.0;
  }

  Map<String, dynamic> emptyNutritionData() {
    return {
      "calories": 0.0,
      "protein": 0.0,
      "carbs": 0.0,
      "fat": 0.0,
      "servingGrams": 100.0,
      "serving": "100g",
      "calcium": 0.0,
      "phosphorus": 0.0,
    };
  }

  Future<Map<String, dynamic>> fetchNutritionData(String query) async {
    try {
      if (query.trim().isEmpty) {
        return emptyNutritionData();
      }

      final uri = Uri.parse(
        _baseUrl,
      ).replace(queryParameters: {'q': query.trim()});

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'X-API-Key':
                  'kal_8dfb5fa1709754c7a83be4b18b5fdae46e86faf799dab0e3b6376a0b05d3a197',
            },
          )
          .timeout(const Duration(seconds: 8));

      print("URL: $uri");
      print("STATUS: ${response.statusCode}");

      if (response.statusCode != 200) {
        return emptyNutritionData();
      }

      final decoded = jsonDecode(response.body);

      if (decoded['success'] != true ||
          decoded['data'] == null ||
          decoded['data'] is! List ||
          decoded['data'].isEmpty) {
        return emptyNutritionData();
      }

      final item = decoded['data'][0];

      final servingText = item['serving']?.toString() ?? "100g";
      final servingGrams = extractServingGrams(servingText);

      return {
        "calories": (item['calories'] as num?)?.toDouble() ?? 0.0,
        "protein": (item['protein'] as num?)?.toDouble() ?? 0.0,
        "carbs": (item['carbs'] as num?)?.toDouble() ?? 0.0,
        "fat": (item['fat'] as num?)?.toDouble() ?? 0.0,
        "servingGrams": servingGrams,
        "serving": servingText,
        "calcium": 0.0,
        "phosphorus": 0.0,
      };
    } on TimeoutException {
      print("Kalori API timeout for query: $query");
      return emptyNutritionData();
    } catch (e) {
      print("Kalori API error for query $query: $e");
      return emptyNutritionData();
    }
  }
}
