import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:staras_mobile/core/controllers/api_client.dart';
import 'package:staras_mobile/model/application/list.shift.model.dart';

class ShiftApiClient {
  Future<ShiftApplicationModel?> fetchShiftDetails(int id) async {
    var apiUrl =
        'https://staras-api.smjle.vn/api/employeeshift/get-registration-detail/$id';

    print(
        'https://staras-api.smjle.vn/api/employeeshift/get-registration-detaild/$id');
    final String? accessToken = await readAccessToken();

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      return ShiftApplicationModel.fromJson(data['data']);
    } else {
      print('Failed to load shift details');
      print(response.body);
      print(response.statusCode);
      return null;
    }
  }
}
