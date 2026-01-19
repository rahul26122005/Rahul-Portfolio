import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_flutter_webside/services/api_service.dart';

class SmsService {
  static Future<void> sendAbsentSMS({
    required String mobile,
    required String studentName,
    required String date,
  }) async {
    final url = Uri.parse("${ApiConfig.localBaseUrl}/send-absent-sms");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "mobile": mobile,
        "studentName": studentName,
        "date": date,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("SMS Failed: ${response.body}");
    }
  }
}
