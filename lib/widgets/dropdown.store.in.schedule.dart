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

class DropdownStoreInScheduleItems extends StatefulWidget {
  final Function(DropdownStore?) onItemSelectedStoreInSchedule;

  const DropdownStoreInScheduleItems(
      {Key? key, required this.onItemSelectedStoreInSchedule})
      : super(key: key);

  @override
  _DropdownStoreInScheduleItemsState createState() =>
      _DropdownStoreInScheduleItemsState();
}

class _DropdownStoreInScheduleItemsState
    extends State<DropdownStoreInScheduleItems> {
  List<DropdownStore>? _dropdownStores;
  DropdownStore? _selectedStore;

  @override
  void initState() {
    super.initState();
    checkTokenExpiration();
    _getDropdownStoreInScheduleItems();
  }

  Future<void> checkTokenExpiration() async {
    final String? accessToken = await readAccessToken();
    if (mounted) {
      await AuthManager.checkTokenExpiration(accessToken!, context);
      _getDropdownStoreInScheduleItems();
    }
  }

  void _getDropdownStoreInScheduleItems() async {
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
        child: DropdownButton2<DropdownStore>(
          isExpanded: true,
          value: _selectedStore ??
              (_dropdownStores?.isNotEmpty == true
                  ? _dropdownStores![0]
                  : null),
          hint: const Row(
            children: [
              Icon(
                Icons.list,
                size: 16,
                color: Colors.yellow,
              ),
              SizedBox(
                width: 4,
              ),
              Expanded(
                child: Text(
                  'Select Item',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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
            widget.onItemSelectedStoreInSchedule(_selectedStore);
          },
          buttonStyleData: ButtonStyleData(
            height: 50,
            width: 170,
            padding: const EdgeInsets.only(left: 14, right: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.black26,
              ),
              color: Colors.white,
            ),
            elevation: 2,
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(
              Icons.arrow_forward_ios_outlined,
            ),
            iconSize: 14,
            iconEnabledColor: kMainColor,
            iconDisabledColor: Colors.grey,
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 200,
            width: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
            ),
            offset: const Offset(-20, 0),
            scrollbarTheme: ScrollbarThemeData(
              radius: const Radius.circular(40),
              thickness: MaterialStateProperty.all(6),
              thumbVisibility: MaterialStateProperty.all(true),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.only(left: 14, right: 14),
          ),
        ),
      ),
    );
  }
}
