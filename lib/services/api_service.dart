import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl =
      'https://your-api.onrender.com/predict';

  Future<String> predict(Map<String, dynamic> input) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(input),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'].toString();
      } else {
        throw Exception(
          'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Prediction failed: $e');
    }
  }
}
