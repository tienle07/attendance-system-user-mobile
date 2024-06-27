import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:staras_mobile/constants/api_consts.dart';
import 'package:staras_mobile/core/controllers/api_client.dart';
import 'package:staras_mobile/core/controllers/check_expired_token.dart';
import 'dart:convert';

import 'package:staras_mobile/model/application/application.type.model.dart';

class MyDropdownMenu extends StatefulWidget {
  final Function(DropdownItem?) onItemSelected;

  const MyDropdownMenu({Key? key, required this.onItemSelected})
      : super(key: key);

  @override
  _MyDropdownMenuState createState() => _MyDropdownMenuState();
}

class _MyDropdownMenuState extends State<MyDropdownMenu> {
  List<DropdownItem>? _dropdownItems;
  DropdownItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    checkTokenExpiration();
    _getDropdownItems();
  }

  Future<void> checkTokenExpiration() async {
    final String? accessToken = await readAccessToken();
    if (mounted) {
      await AuthManager.checkTokenExpiration(accessToken!, context);
      _getDropdownItems();
    }
  }

  Future<void> _getDropdownItems() async {
    var apiUrl = '$BASE_URL/api/applicationtype/get-type-list';
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];

        // setState(() {
        //   _dropdownItems = data.map((item) {
        //     return DropdownItem.fromJson(item);
        //   }).toList();
        // });
        setState(() {
          _dropdownItems = data
              .where((item) => item['status'] == 2)
              .map((item) => DropdownItem.fromJson(item))
              .toList();
        });
      } else {
        print('Failed to load dropdown items');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        controller: ScrollController(),
        child: DropdownButtonFormField<DropdownItem>(
          value: _selectedItem,
          decoration: const InputDecoration(
            hintText: 'Select Category',
            border: OutlineInputBorder(),
          ),
          items: _dropdownItems
              ?.map((item) => DropdownMenuItem<DropdownItem>(
                    value: item,
                    child: Text(item.name ?? ''),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedItem = value;
            });
            widget.onItemSelected(_selectedItem);
          },
        ),
      ),
    );
  }
}
