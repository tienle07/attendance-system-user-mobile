import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:staras_mobile/constants/api_consts.dart';
import 'package:staras_mobile/core/controllers/api_client.dart';
import 'package:staras_mobile/model/employee/employee.profile.model.dart';

class EmployeeApi {
  //profile employee
  static Future<EmployeeProfileModel?> fetchProfile(String? accessToken) async {
    final String? employeeId = await readEmployeeId();
    var apiUrl = '$BASE_URL/api/employee/get-employee-detail/$employeeId';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data = json.decode(response.body);
      return EmployeeProfileModel.fromJson(data['data']);
    } else {
      print('Failed to load profile employee');
      print(response.body);
      print(response.statusCode);
      return null;
    }
  }
}
