import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:staras_mobile/constants/api_consts.dart';

import 'package:staras_mobile/core/controllers/api_client.dart';
import 'package:staras_mobile/model/store/details.store.model.dart';

class StoreApiClient {
  //Get Api List Store
  // Future<List<StoreModel>> fetchStoreData(
  //     {String? searchText, bool? active}) async {
  //   final String? accessToken = await readAccessToken();

  //   var apiUrl = '$BASE_URL/store/hr-get-store-list';
  //   var apiUrlWithParams =
  //       searchText != null ? '$apiUrl?StoreName=$searchText' : apiUrl;

  //   if (active != null) {
  //     apiUrlWithParams += apiUrlWithParams.contains('?') ? '&' : '?';
  //     apiUrlWithParams += 'Active=$active';
  //   }

  //   try {
  //     final response = await http.get(
  //       Uri.parse(apiUrl),
  //       headers: <String, String>{
  //         'Content-Type': 'application/json',
  //         'Accept': 'application/json',
  //         'Authorization': 'Bearer $accessToken',
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> responseData = json.decode(response.body);

  //       if (responseData.containsKey('data')) {
  //         final List<dynamic> storeData = responseData['data'];

  //         final List<StoreModel> storeList =
  //             storeData.map((json) => StoreModel.fromJson(json)).toList();

  //         return storeList;
  //       } else {
  //         print(
  //             'API Error: Response does not contain the expected data structure.');
  //         return [];
  //       }
  //     } else {
  //       print('API Error: ${response.statusCode}, ${response.body}');
  //       return [];
  //     }
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Error: $e');
  //     }
  //     return [];
  //   }
  // }

  //Get Details Store
  Future<DetailsStoreModel?> fetchStoreDetails(int storeId) async {
    var apiUrl = '$BASE_URL/api/store/get-store-infor/$storeId';

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

      return DetailsStoreModel.fromJson(data['data']);
    } else {
      print('Failed to load store details');
      print(response.body);
      print(response.statusCode);
      return null;
    }
  }
}
