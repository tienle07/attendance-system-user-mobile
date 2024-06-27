// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:staras_mobile/constants/constant.dart';
import 'package:staras_mobile/view/bottomBar/bottomBar.dart';
import 'package:staras_mobile/view/screens/HomeScreen/home_screen_employee.dart';

import 'on_board.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<Future<void>?> init() async {
    await Future.delayed(const Duration(seconds: 2));

    defaultBlurRadius = 10.0;
    defaultSpreadRadius = 0.5;

    try {
      // Check if access token is still valid
      final String? accessToken =
          await _secureStorage.read(key: 'access_token');
      print("Access token Spalash: ${accessToken} ");
      if (accessToken != null) {
        final bool isTokenValid = await checkTokenValidity(accessToken);
        if (isTokenValid) {
          return Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BottomBar(),
            ),
          );
        }
      }
    } catch (e) {
      print('Error reading access token: $e');
    }

    // Access token has expired or not found, proceed with OnBoard screen
    return const OnBoard().launch(context, isNewTask: true);
  }

  Future<bool> checkTokenValidity(String accessToken) async {
    try {
      Map<String, dynamic>? decodedToken = JwtDecoder.decode(accessToken);
      int? expirationTime = decodedToken?['exp'];
      print("exp spalash screen: ${expirationTime} ");

      if (expirationTime != null) {
        DateTime expirationDateTime =
            DateTime.fromMillisecondsSinceEpoch(expirationTime * 1000);
        DateTime currentDateTime = DateTime.now();
        print("Time Token Spalash : ${expirationDateTime} ");

        return currentDateTime.isBefore(expirationDateTime);
      }

      return false;
    } catch (e) {
      print('Error decoding accessToken: $e');
      return false;
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kMainColor,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height / 3,
            ),
            const Image(
              image: AssetImage('images/logo.png'),
              width: 240,
              height: 240,
            ),
            const Spacer(),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  'Version 1.0.0',
                  style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                      fontSize: 15.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
