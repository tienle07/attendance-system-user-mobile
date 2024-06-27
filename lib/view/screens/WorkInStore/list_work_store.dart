// ignore_for_file: library_private_types_in_public_api, depend_on_referenced_packages

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:staras_mobile/constants/api_consts.dart';
import 'package:staras_mobile/constants/constant.dart';
import 'package:staras_mobile/core/controllers/api_client.dart';
import 'package:staras_mobile/core/controllers/check_expired_token.dart';
import 'package:staras_mobile/model/store/work.store.model.dart';
import 'package:staras_mobile/view/screens/WorkInStore/detail_work_store.dart';

class ListWorkStore extends StatefulWidget {
  const ListWorkStore({Key? key}) : super(key: key);

  @override
  _ListWorkStoreState createState() => _ListWorkStoreState();
}

class _ListWorkStoreState extends State<ListWorkStore> {
  List<WorkStoreModel>? stores;

  @override
  void initState() {
    super.initState();
    checkTokenExpiration();
    fetchListWorkStore();
  }

  Future<void> checkTokenExpiration() async {
    final String? accessToken = await readAccessToken();
    if (mounted) {
      await AuthManager.checkTokenExpiration(accessToken!, context);
      fetchListWorkStore();
    }
  }

  Future<void> fetchListWorkStore() async {
    final String? accessToken = await readAccessToken();
    var apiUrl = '$BASE_URL/api/employeeinstore/get-employee-working-store';
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> storeData = json.decode(response.body);

      if (storeData.containsKey('data') && storeData['data'] is List) {
        List<dynamic> storesData = storeData['data'];

        List<WorkStoreModel> storeList = storesData
            .map((storeData) => WorkStoreModel.fromJson(storeData))
            .toList();

        setState(() {
          stores = storeList;
          print('Store List: $storeList');
        });
      } else {
        print('No machines data found in the response');
      }
    } else {
      print('Failed to load machines');
      print(response.body);
      print(response.statusCode);
    }
  }

  String getStatusText(int status) {
    switch (status) {
      case -1:
        return 'Not Working';
      case 0:
        return 'New';
      case 1:
        return 'Ready';
      case 2:
        return 'Working';
      default:
        return '';
    }
  }

  Color getStatusColor(int status) {
    switch (status) {
      case -1:
        return Colors.red;
      case 0:
        return Colors.yellow;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      default:
        return Colors.black; // You can set a default color here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: kMainColor,
      appBar: AppBar(
        backgroundColor: kMainColor,
        elevation: 0.0,
        titleSpacing: 0.0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Work List Store',
          maxLines: 2,
          style: kTextStyle.copyWith(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 20.0,
          ),
          Expanded(
            child: Container(
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
                  Expanded(
                    child: ListView.builder(
                      itemCount: stores?.length,
                      itemBuilder: (context, index) {
                        final store = stores?[index];
                        return Column(
                          children: [
                            Material(
                              elevation: 2.0,
                              child: Container(
                                width: context.width(),
                                padding: const EdgeInsets.all(10.0),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: Color.fromARGB(255, 137, 188, 9),
                                      width: 3.0,
                                    ),
                                  ),
                                  color: Colors.white,
                                ),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailsStore(
                                          id: store?.storeId ?? 0,
                                        ),
                                      ),
                                    );
                                  },
                                  leading: Icon(
                                    Icons.store_mall_directory_outlined,
                                    size: 35,
                                    color: kMainColor,
                                  ),
                                  title: Text(
                                    store?.storeName ?? '',
                                    maxLines: 2,
                                    style: kTextStyle.copyWith(
                                      color: kTitleColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Position:    ${store?.positionName ?? ''}',
                                        maxLines: 2,
                                        style: kTextStyle.copyWith(
                                          color: kTitleColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'Assigned: ${DateFormat('dd, MMMM yyyy').format(store?.assignedDate ?? DateTime.now())}',
                                        style: kTextStyle.copyWith(
                                          color: kTitleColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            "Type: ",
                                            style: kTextStyle.copyWith(
                                              color: kTitleColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            " ${store?.typeName ?? ''}",
                                            style: kTextStyle.copyWith(
                                              color: kMainColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            "Status: ",
                                            style: kTextStyle.copyWith(
                                              color: kTitleColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (store?.status != null) ...[
                                            SizedBox(height: 5),
                                            Text(
                                              getStatusText(store!.status!),
                                              style: kTextStyle.copyWith(
                                                fontSize: 12,
                                                color: getStatusColor(
                                                    store.status!),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 20.0,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
