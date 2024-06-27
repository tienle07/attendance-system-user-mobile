// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:staras_mobile/common/toast.dart';
import 'package:staras_mobile/components/button_global.dart';
import 'package:staras_mobile/constants/api_consts.dart';
import 'package:staras_mobile/constants/constant.dart';
import 'package:staras_mobile/core/controllers/refresh_token_service.dart';
import 'package:staras_mobile/model/login_model.dart';
import 'package:staras_mobile/view/bottomBar/bottomBar.dart';
import 'package:staras_mobile/view/screens/Authentication/forgot_password.dart';

class SignInEmployee extends StatefulWidget {
  const SignInEmployee({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _SignInEmployeeState createState() => _SignInEmployeeState();
}

class _SignInEmployeeState extends State<SignInEmployee> {
  final _form = GlobalKey<FormState>();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final TokenRefreshService _tokenRefreshService = TokenRefreshService();
  bool isChecked = false;

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> loginEmployee() async {
    if (_form.currentState!.validate()) {
      onLoading(context);
      const String apiUrl = '$BASE_URL/api/authenticate';

      final Map<String, dynamic> loginData = {
        'username': usernameController.text,
        'password': passwordController.text,
      };

      final String jsonBody = jsonEncode(loginData);

      try {
        final http.Response response = await http.post(
          Uri.parse(apiUrl),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonBody,
        );

        Navigator.pop(context);
        if ((response.statusCode >= 400 && response.statusCode <= 500)) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final String errorMessage = responseData['message'];
          showToast(
            context: context,
            msg: errorMessage,
            color: Colors.red,
            icon: const Icon(Icons.error),
          );
          print('Access Token Not found on the response');
        } else if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final LoginModel loginModel =
              LoginModel.fromJson(responseData['data']);

          final String? accessToken = loginModel.token?.accessToken;
          final String? refreshToken = loginModel.token?.refreshToken;
          final int? accountId = loginModel.account?.id;
          final int? employeeId = loginModel.account?.employeeId;
          final int? employeeRoleId = loginModel.account?.roleId;
          final String? username = loginModel.account?.username;

          const int ROLE_EMPLOYEE = 4;

          if (accessToken != null) {
            //save access token
            await _secureStorage.write(key: 'access_token', value: accessToken);
            await _secureStorage.write(
                key: 'refresh_token', value: refreshToken);

            await _secureStorage.write(
                key: 'accountId', value: accountId.toString());
            await _secureStorage.write(
                key: 'employeeId', value: employeeId.toString());
            await _secureStorage.write(
                key: 'username', value: username.toString());

            if (employeeRoleId == ROLE_EMPLOYEE) {
              showToast(
                context: context,
                msg: "Login Successfully",
                color: Color.fromARGB(255, 128, 249, 16),
                icon: const Icon(Icons.done),
              );
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => BottomBar(),
                ),
                (route) => false,
              );
            } else {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Unauthorized Access',
                        style: kTextStyle.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[200],
                        )),
                    content: Text(
                      'You are not authorized as Employee',
                      style: kTextStyle.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    actions: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TextButton(
                            child: Text('OK',
                                style: kTextStyle.copyWith(
                                  color: kMainColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                )),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            }
          } else {
            print('Access Token Not found on the response');
          }
        } else if (response.statusCode == 401) {
          await _tokenRefreshService.refreshAccessToken();
        } else {
          print('Error: ${response.statusCode}');
          print('Body: ${response.body}');
        }
      } catch (e) {
        // Handle network or other errors
        if (kDebugMode) {
          print('Error: $e');
        }
      }
    }
  }

  Future<void> refreshAccessToken() async {
    final String? refreshToken =
        await _secureStorage.read(key: 'refresh_token');

    if (refreshToken != null) {
      final Map<String, dynamic> refreshData = {
        'username': null,
        'password': null,
        'refreshToken': refreshToken,
      };

      // Convert the Map to JSON
      final String jsonBody = jsonEncode(refreshData);

      try {
        // Make the API request to refresh the access token
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
          final LoginModel refreshedModel =
              LoginModel.fromJson(refreshedData['data']);

          final String? newAccessToken = refreshedModel.token?.accessToken;
          final String? newRefreshToken = refreshedModel.token?.refreshToken;

          // Update the new access token
          await _secureStorage.write(
              key: 'access_token', value: newAccessToken);
          await _secureStorage.write(
              key: 'refresh_token', value: newRefreshToken);

          // You can now proceed with your logic using the new access token
          print('Access token refreshed successfully.');

          // Add your logic here if needed
        } else {
          print('Error refreshing access token: ${refreshResponse.statusCode}');
          print('Body: ${refreshResponse.body}');
        }
      } catch (e) {
        print('Error refreshing access token: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double containerHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: kMainColor,
      appBar: AppBar(
        backgroundColor: kMainColor,
        elevation: 0.0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            'Sign In',
            style: kTextStyle.copyWith(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 30, bottom: 10),
              child: Text(
                'Sign In with Role Employee',
                style: kTextStyle.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              height: containerHeight,
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0)),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: 20.0,
                  ),
                  SizedBox(
                    height: 280.0, // Adjust the height as needed
                    child: Lottie.asset(
                      "assets/animation_lne3q6xp.json",
                      fit: BoxFit.contain, // Adjust the fit as needed
                    ),
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  TextFormField(
                    controller: usernameController,
                    style:
                        kTextStyle.copyWith(fontSize: 15, color: Colors.black),
                    enabled: true,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(20, 15, 10, 15),
                      labelText: 'Username',
                      hintText: 'Enter Username',
                      labelStyle: kTextStyle,
                      hintStyle: kTextStyle.copyWith(
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          15,
                        ),
                      ),
                    ),
                    validator: (usernameController) {
                      if (usernameController == null ||
                          usernameController.isEmpty) {
                        return 'Please enter username';
                      } else if (!(usernameController!.length > 5)) {
                        return "Username more than 5 characters!";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  AppTextField(
                    controller: passwordController,
                    textStyle:
                        kTextStyle.copyWith(fontSize: 15, color: Colors.black),
                    textFieldType: TextFieldType.PASSWORD,
                    enabled: true,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(20, 15, 10, 15),
                      labelText: 'Password',
                      labelStyle: kTextStyle,
                      hintText: 'Enter your password',
                      hintStyle: kTextStyle.copyWith(fontSize: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    validator: (passwordController) {
                      if (passwordController == null ||
                          passwordController.isEmpty) {
                        return 'Please enter your password';
                      } else if (!(passwordController!.length > 5)) {
                        return "Password contain more than 5 characters";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  Row(
                    children: [
                      Transform.scale(
                        scale: 0.8,
                        child: CupertinoSwitch(
                          value: isChecked,
                          activeColor: kMainColor,
                          thumbColor: kGreyTextColor,
                          onChanged: (bool value) {
                            setState(() {
                              isChecked = value;
                            });
                          },
                        ),
                      ),
                      Text(
                        'Save Me',
                        style: kTextStyle,
                      ),
                      const Spacer(),
                      Text(
                        'Forgot Password?',
                        style: kTextStyle,
                      ).onTap(() {
                        const ForgotPassword().launch(context);
                      }),
                    ],
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  ButtonGlobal(
                      buttontext: 'Sign In',
                      buttonDecoration:
                          kButtonDecoration.copyWith(color: kMainColor),
                      onPressed: () {
                        loginEmployee();
                      }),
                  const SizedBox(
                    height: 20.0,
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
