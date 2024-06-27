import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:staras_mobile/core/controllers/api_client.dart';
import 'package:staras_mobile/core/controllers/refresh_token_service.dart';
import 'package:staras_mobile/view/screens/Authentication/sign_in_employee.dart';

class AuthManager {
  static TokenRefreshService _tokenRefreshService = TokenRefreshService();

  static Future<void> checkTokenExpiration(
      String accessToken, BuildContext context) async {
    final String? accessToken = await readAccessToken();
    try {
      Map<String, dynamic>? decodedToken = JwtDecoder.decode(accessToken!);
      int? expirationTime = decodedToken['exp'];

      print("exp of HomeScreen: ${expirationTime}");

      if (expirationTime != null) {
        DateTime expirationDateTime =
            DateTime.fromMillisecondsSinceEpoch(expirationTime * 1000);
        DateTime currentDateTime = DateTime.now();

        print("Expiration Token Home${expirationDateTime}");

        Duration threshold = Duration(seconds: 240);
        print(threshold);

        if (currentDateTime.isAfter(expirationDateTime.subtract(threshold))) {
          await _tokenRefreshService.refreshAccessToken();
        }
      }
    } catch (e) {
      print('Error decoding accessToken: $e');
    }
  }

  static Future<void> navigateToSignInEmployee(BuildContext context) async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignInEmployee()),
    );
  }
}
