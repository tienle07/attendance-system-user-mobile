// ignore_for_file: library_private_types_in_public_api

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:staras_mobile/constants/api_consts.dart';
import 'package:staras_mobile/constants/constant.dart';
import 'dart:convert';

import 'package:staras_mobile/core/controllers/api_client.dart';
import 'package:staras_mobile/core/controllers/check_expired_token.dart';

import 'package:staras_mobile/model/store/dropdown.store.model.dart';

class DropdownStoreInLeaveApplication extends StatefulWidget {
  final Function(DropdownStore?) onItemSelectedStoreInLeaveApplication;

  const DropdownStoreInLeaveApplication(
      {Key? key, required this.onItemSelectedStoreInLeaveApplication})
      : super(key: key);

  @override
  _DropdownStoreInLeaveApplicationState createState() =>
      _DropdownStoreInLeaveApplicationState();
}

class _DropdownStoreInLeaveApplicationState
    extends State<DropdownStoreInLeaveApplication> {
  List<DropdownStore>? _dropdownStores;
  DropdownStore? _selectedStore;

  @override
  void initState() {
    super.initState();
    checkTokenExpiration();
    _getDropdownStoreInLeaveApplication();
  }

  Future<void> checkTokenExpiration() async {
    final String? accessToken = await readAccessToken();
    if (mounted) {
      await AuthManager.checkTokenExpiration(accessToken!, context);
      _getDropdownStoreInLeaveApplication();
    }
  }

  void _getDropdownStoreInLeaveApplication() async {
    try {
      final String? accessToken = await readAccessToken();

      final response = await http.get(
        Uri.parse('$BASE_URL/api/employeeinstore/get-employee-working-store'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];

        setState(() {
          // Filter stores with status = 2
          _dropdownStores = data
              .where((item) => [2, 1, 0].contains(item['status']))
              .map((item) => DropdownStore.fromJson(item))
              .toList();
        });
      } else {
        print(
            'Failed to load dropdown store items. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField2<DropdownStore>(
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            // Add more decoration..
          ),
          value: _selectedStore ??
              (_dropdownStores?.isNotEmpty == true
                  ? _dropdownStores![0]
                  : null),
          hint: Text(
            'Select Store',
            style: kTextStyle.copyWith(fontSize: 14),
          ),
          items: _dropdownStores?.map((item) {
            return DropdownMenuItem<DropdownStore>(
              value: item,
              child: Text(
                item.storeName ?? '',
                style: kTextStyle.copyWith(
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedStore = value;
            });
            widget.onItemSelectedStoreInLeaveApplication(_selectedStore);
          },
          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.only(right: 8),
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(
              Icons.arrow_drop_down,
              color: Colors.black45,
            ),
            iconSize: 24,
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }
}
