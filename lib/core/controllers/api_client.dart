// ignore_for_file: unused_catch_clause, prefer_const_constructors

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

String baseUrl = "https://staras-api.smjle.xyz";

final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

Future<String?> readAccessToken() async {
  return await _secureStorage.read(key: 'access_token');
}

Future<String?> readRefreshToken() async {
  return await _secureStorage.read(key: 'refresh_token');
}

Future<void> deleteAccessToken() async {
  await _secureStorage.delete(key: 'access_token');
}

Future<void> deleteRefreshToken() async {
  await _secureStorage.read(key: 'refresh_token');
}

Future<String?> readAccountId() async {
  return await _secureStorage.read(key: 'accountId');
}

Future<String?> readEmployeeId() async {
  return await _secureStorage.read(key: 'employeeId');
}

Future<String?> readUsername() async {
  return await _secureStorage.read(key: 'username');
}

httpGet(url, context) async {
  final String? accessToken = await readAccessToken();
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };
  var responseGet = await http.get(Uri.parse('$baseUrl$url'), headers: headers);
  if (responseGet.statusCode == 200 &&
      responseGet.headers["content-type"] == 'application/json') {
    try {
      return {
        "headers": responseGet.headers,
        "body": json.decode(utf8.decode(responseGet.bodyBytes))
      };
    } on FormatException catch (e) {
      //bypass
    }
  } else {
    return {
      "headers": responseGet.headers,
      "body": utf8.decode(responseGet.bodyBytes)
    };
  }
}

//thêm bản ghi
httpPost(url, requestBody, context) async {
  final String? accessToken = await readAccessToken();
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };
  var finalRequestBody = json.encode(requestBody);
  var response = await http.post(Uri.parse("$baseUrl$url".toString()),
      headers: headers, body: finalRequestBody);
  if (response.statusCode == 200 &&
      response.headers["content-type"] == 'application/json') {
    try {
      return {
        "headers": response.headers,
        "body": json.decode(utf8.decode(response.bodyBytes))
      };
    } on FormatException catch (e) {
      //bypass
    }
  } else {
    return {
      "headers": response.headers,
      "body": utf8.decode(response.bodyBytes)
    };
  }
}

//cập nhật bản ghi
httpPut(url, requestBody, context) async {
  Map<String, String> headers = {'content-type': 'application/json'};
  var finalRequestBody = json.encode(requestBody);
  var response = await http.put(Uri.parse('$baseUrl$url'),
      headers: headers, body: finalRequestBody);
  if (response.statusCode == 200 &&
      response.headers["content-type"] == 'application/json') {
    try {
      return {
        "headers": response.headers,
        "body": json.decode(utf8.decode(response.bodyBytes))
      };
    } on FormatException catch (e) {
      //bypass
    }
  } else {
    return {
      "headers": response.headers,
      "body": utf8.decode(response.bodyBytes)
    };
  }
}

//xóa bản ghi
httpDelete(url, context) async {
  Map<String, String> headers = {'content-type': 'application/json'};
  var response = await http.delete(Uri.parse('$baseUrl$url'), headers: headers);
  if (response.statusCode == 200 &&
      response.headers["content-type"] == 'application/json') {
    try {
      return {
        "headers": response.headers,
        "body": json.decode(utf8.decode(response.bodyBytes))
      };
    } on FormatException catch (e) {
      //bypass
    }
  } else {
    return {
      "headers": response.headers,
      "body": utf8.decode(response.bodyBytes)
    };
  }
}

// void downloadFile(String fileName) {
//   html.AnchorElement anchorElement = html.AnchorElement(href: fileName);
//   anchorElement.download = fileName;
//   anchorElement.click();
// }