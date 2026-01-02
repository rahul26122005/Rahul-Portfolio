import 'package:cloud_functions/cloud_functions.dart';

class SmsService {
  static final _functions = FirebaseFunctions.instance;

  static Future<void> sendAbsentSMS({
    required String mobile,
    required String studentName,
    required String date,
  }) async {
    final callable =
        _functions.httpsCallable('sendAbsentSMS');

    await callable.call({
      'mobile': mobile,
      'studentName': studentName,
      'date': date,
    });
  }
}
