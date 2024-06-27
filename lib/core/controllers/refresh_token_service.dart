// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:staras_mobile/constants/api_consts.dart';

class TokenRefreshService {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> refreshAccessToken() async {
    final String? refreshToken =
        await _secureStorage.read(key: 'refresh_token');

    if (refreshToken != null) {
      final Map<String, dynamic> refreshData = {
        'username': null,
        'password': null,
        'refreshToken': refreshToken,
      };

      final String jsonBody = jsonEncode(refreshData);

      try {
        final http.Response refreshResponse = await http.post(
          Uri.parse('$BASE_URL/api/authenticate'),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonBody,
        );

        if (refreshResponse.statusCode == 200) {
          final Map<String, dynamic> refreshedData =
              jsonDecode(refreshResponse.body);
          final String? newAccessToken =
              refreshedData['data']['token']['accessToken'];
          final String? newRefreshToken =
              refreshedData['data']['token']['refreshToken'];

          await _secureStorage.write(
              key: 'access_token', value: newAccessToken);
          await _secureStorage.write(
              key: 'refresh_token', value: newRefreshToken);

          print('Access token refreshed successfully.');
        } else {
          print('Error refreshing access token: ${refreshResponse.statusCode}');
          print('Body: ${refreshResponse.body}');
        }
      } catch (e) {
        print('Error refreshing access token: $e');
      }
    }
  }
}
