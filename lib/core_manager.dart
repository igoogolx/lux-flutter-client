import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Must be top-level function
Map<String, dynamic> _parseAndDecode(String response) {
  return jsonDecode(response) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> parseJson(String text) {
  return compute(_parseAndDecode, text);
}

class CoreManager {
  final String baseUrl;

  final dio = Dio();

  CoreManager(this.baseUrl) {
    dio.transformer = BackgroundTransformer()..jsonDecodeCallback = parseJson;
  }

  void run() async {}
}
