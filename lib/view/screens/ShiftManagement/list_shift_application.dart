// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison, unnecessary_string_interpolations

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:staras_mobile/common/toast.dart';
import 'package:staras_mobile/constants/api_consts.dart';
import 'package:staras_mobile/constants/constant.dart';
import 'package:http/http.dart' as http;
import 'package:staras_mobile/core/controllers/api_client.dart';
import 'package:staras_mobile/core/controllers/check_expired_token.dart';
import 'package:staras_mobile/model/application/list.shift.model.dart';
import 'package:staras_mobile/model/store/dropdown.store.model.dart';
import 'package:staras_mobile/view/screens/ShiftManagement/shift_apply.dart';
import 'package:staras_mobile/widgets/dropdown.store.in.shift.dart';

class ListShiftApplication extends StatefulWidget {
  const ListShiftApplication({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ListShiftApplicationState createState() => _ListShiftApplicationState();
}

class _ListShiftApplicationState extends State<ListShiftApplication> {
  DropdownStore? _selectedStore;
  List<ShiftApplicationModel> application = [];
  List<DropdownStore>? _dropdownStores;
  TextEditingController note = TextEditingController();

  List<String> types = ['All', 'Approved', 'Pending', 'Rejected', 'Canceled'];
  String selected = 'All';

  @override
  void initState() {
    super.initState();
    _getDropdownStoreInShiftItems();
    checkTokenExpiration();
  }

  Future<void> checkTokenExpiration() async {
    final String? accessToken = await readAccessToken();
    if (mounted) {
      await AuthManager.checkTokenExpiration(accessToken!, context);
      if (_selectedStore != null) {
        fetchShiftApplicationData(_selectedStore!.storeId);
      }
    }
  }

  void _onDropdownStoreInShiftSelected(DropdownStore? selectedStore) {
    setState(() {
      _selectedStore = selectedStore!;
      fetchShiftApplicationData(selectedStore.storeId);
    });
  }

  void _getDropdownStoreInShiftItems() async {
    try {
      final String? accessToken = await readAccessToken();
      final String? id = await readEmployeeId();
      print(id);

      final response = await http.get(
        Uri.parse(
          '$BASE_URL/api/employeeinstore/get-employee-working-store',
        ),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];

        setState(() {
          _dropdownStores = data.map((item) {
            return DropdownStore.fromJson(item);
          }).toList();

          _selectedStore =
              _dropdownStores?.isNotEmpty ?? false ? _dropdownStores![0] : null;

          if (_selectedStore != null) {
            fetchShiftApplicationData(_selectedStore!.storeId);
          }
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

  String formatTime(int totalSeconds) {
    if (totalSeconds <= 0) return '';

    final int days = totalSeconds ~/ 86400;
    final int remainingSeconds = totalSeconds % 86400;
    final int hours = remainingSeconds ~/ 3600;
    final int minutes = (remainingSeconds % 3600) ~/ 60;
    final int seconds = remainingSeconds % 60;

    if (days > 0) {
      return '$days d${days > 1 ? '' : ''}';
    } else if (hours > 0) {
      return '$hours h${hours > 1 ? '' : ''}';
    } else if (minutes > 0) {
      return '$minutes m${minutes > 1 ? '' : ''}';
    } else {
      return '$seconds s${seconds > 1 ? '' : ''}';
    }
  }

  Color getBorderColor(String? shiftName) {
    switch (shiftName) {
      case 'Morning':
        return Colors.green[300] ?? Colors.green;
      case 'Afternoon':
        return Colors.blue[200] ?? Colors.blue;
      case 'Evening':
        return Colors.orange[200] ?? Colors.orange;
      default:
        return Colors.yellow[200] ?? Colors.yellow;
    }
  }

  Future<void> fetchShiftApplicationData(int? storeId, {int? status}) async {
    final String? accessToken = await readAccessToken();
    final String? employeeId = await readEmployeeId();

    var apiUrl =
        '$BASE_URL/api/employeeshift/get-work-registration?EmployeeId=$employeeId&StoreId=$storeId';

    if (status != null) {
      apiUrl += '&Status=$status';
    }

    print(apiUrl);

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('data')) {
          final List<dynamic>? employeeData = responseData['data'];

          if (employeeData != null) {
            final List<ShiftApplicationModel> applicationList = employeeData
                .map((json) {
                  try {
                    return ShiftApplicationModel.fromJson(json);
                  } catch (e) {
                    print('Error parsing shift application data: $e');
                    return null;
                  }
                })
                .whereType<ShiftApplicationModel>()
                .toList();

            setState(() {
              application = applicationList;
            });
          } else {
            print('Data is null');
            setState(() {
              application = [];
            });
          }
        } else {
          print('Response does not contain key "data": $responseData');
          setState(() {
            application = [];
          });
        }
      } else if (response.statusCode == 204) {
        setState(() {
          application = [];
        });
      } else {
        print('Unexpected status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error during API request: $e');
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  Future<void> cancelShiftApplication(
      ShiftApplicationModel application, String note) async {
    try {
      final String? accessToken = await readAccessToken();
      var apiUrl = '$BASE_URL/api/employeeshift/employee-cancel-registration';

      final List<dynamic> requestBody = [
        {
          'employeeShiftId': application.id,
          'note': note,
        }
      ];

      final response = await http.put(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      print(requestBody.toString());

      if (response.statusCode == 201) {
        showToast(
          context: context,
          msg: "Shift registration canceled successfully",
          color: Color.fromARGB(255, 128, 249, 16),
          icon: const Icon(Icons.done),
        );

        print('Shift application canceled successfully');
      } else {
        final Map<String, dynamic> errorResponse = json.decode(response.body);
        final String errorMessage = errorResponse['message'] ?? 'Unknown error';

        showToast(
          context: context,
          msg: errorMessage,
          color: Colors.red,
          icon: const Icon(Icons.error),
        );
        print(
            'Failed to cancel shift application. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> _showShiftDetailsDialog(
      ShiftApplicationModel application) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool showCancelButton = application.status == 0;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide(color: kMainColor, width: 2.0),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shift Details',
                style: kTextStyle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kMainColor,
                ),
              ),
              if (showCancelButton)
                ElevatedButton(
                  onPressed: () {
                    _showCancelConfirmationDialog(application);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8.0), // Button border radius
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style:
                        kTextStyle.copyWith(color: Colors.white, fontSize: 10),
                  ),
                ),
            ],
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Shift: ',
                    style: kTextStyle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${application.shiftName ?? ""}',
                    style: kTextStyle.copyWith(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // or CrossAxisAlignment.center
                children: [
                  Text(
                    'Name: ',
                    style: kTextStyle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${application.employeeName ?? ""}',
                      style: kTextStyle.copyWith(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Time: ',
                    style: kTextStyle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${application.startTime != null ? DateFormat('HH:mm a').format(application.startTime!) : ""} -  ${application.endTime != null ? DateFormat('HH:mm a').format(application.endTime!) : ""}',
                    style: kTextStyle.copyWith(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (application.status == 1 || application.status == -1)
                Row(
                  children: [
                    Text(
                      'Approve Date: ',
                      style: kTextStyle.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${application.approvalDate != null ? DateFormat('yyyy MMMM, dd').format(application.approvalDate!) : ""}',
                      style: kTextStyle.copyWith(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              if (application.status == -2)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // or CrossAxisAlignment.center
                      children: [
                        Text(
                          'Note: ',
                          style: kTextStyle.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${application.note ?? ""}',
                            style: kTextStyle.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Update Date: ',
                          style: kTextStyle.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${application.updateDate != null ? DateFormat('yyyy MMMM, dd').format(application.updateDate!) : ""}',
                          style: kTextStyle.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: kTextStyle.copyWith(
                    fontSize: 15,
                    color: Colors.blue[200],
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCancelConfirmationDialog(
    ShiftApplicationModel application,
  ) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide(color: kMainColor, width: 2.0),
          ),
          title: Text(
            'Cancel Shift Registration',
            style: kTextStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kMainColor,
            ),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to cancel the Shift Registration?',
                style: kTextStyle.copyWith(
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20), // Add spacing
              TextFormField(
                controller: note,
                style: kTextStyle.copyWith(fontSize: 15, color: Colors.black),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(10, 20, 10, 15),
                  labelText: 'Note(Optional)',
                  labelStyle: kTextStyle,
                  hintStyle: kTextStyle.copyWith(fontSize: 15),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                cancelShiftApplication(application, note.text);
                note.clear();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                fetchShiftApplicationData(_selectedStore!.storeId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kRedColor,
              ),
              child: Text(
                'Yes',
                style: kTextStyle.copyWith(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
              ),
              child: Text(
                'No',
                style: kTextStyle.copyWith(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (BuildContext context) => const ShiftApply(),
          //   ),
          // );

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ShiftApply(
                onRegisterShiftSuccess: () {
                  if (_selectedStore != null) {
                    fetchShiftApplicationData(_selectedStore!.storeId);
                  }
                },
              ),
            ),
          );
        },
        backgroundColor: kMainColor,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      resizeToAvoidBottomInset: false,
      backgroundColor: kMainColor,
      appBar: AppBar(
        backgroundColor: kMainColor,
        elevation: 0.0,
        titleSpacing: 0.0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            'View Registration',
            maxLines: 2,
            style: kTextStyle.copyWith(
              color: kDarkWhite,
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: context.width(),
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20.0,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.mail_outline_outlined,
                      ),
                      SizedBox(width: 15.0),
                      Text(
                        "List Shift Request",
                        style: kTextStyle.copyWith(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 40.0,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.store_mall_directory_outlined,
                        color: kMainColor,
                      ),
                      SizedBox(width: 5.0),
                      Text(
                        ' Please Select a Store',
                        style: kTextStyle.copyWith(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  DropdownStoreInShiftItems(
                      onItemSelectedStoreInShift:
                          _onDropdownStoreInShiftSelected),
                  const SizedBox(
                    height: 30.0,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30.0),
                        topRight: Radius.circular(30.0),
                      ),
                      color: kBgColor,
                    ),
                    child: HorizontalList(
                      spacing: 0,
                      itemCount: types.length,
                      itemBuilder: (_, i) {
                        // Determine whether to show the count based on the selected status
                        String countText = selected == types[i]
                            ? ' (${application.length.toString()})'
                            : '';

                        return Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            '${types[i]}$countText',
                            style: kTextStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              color: selected == types[i]
                                  ? kMainColor
                                  : kGreyTextColor,
                            ),
                          ).onTap(() {
                            setState(() {
                              selected = types[i];
                              int? status;
                              switch (types[i]) {
                                case 'All':
                                  status = null;
                                  break;
                                case 'Approved':
                                  status = 1;
                                  break;
                                case 'Pending':
                                  status = 0;
                                  break;
                                case 'Rejected':
                                  status = -1;
                                  break;
                                case 'Canceled':
                                  status = -2;
                                  break;
                              }
                              fetchShiftApplicationData(_selectedStore!.storeId,
                                  status: status);
                            });
                          }),
                        );
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  // Inside the build method, replace the existing Expanded widget with the updated one:

                  Expanded(
                    child: application == null || application.isEmpty
                        ? Container(
                            child: Center(
                              child: Text(
                                'No Shift Request',
                                style: kTextStyle.copyWith(
                                  color: kTitleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: application.length,
                            itemBuilder: (context, index) {
                              final ShiftApplicationModel app =
                                  application[index];

                              final formattedDateWork = app.startTime != null
                                  ? DateFormat('dd/MM/yyyy')
                                      .format(app.startTime!)
                                  : "";
                              String formattedCrHour = formatTime(
                                  app.registerDate != null
                                      ? DateTime.now()
                                          .difference(app.registerDate!)
                                          .inSeconds
                                      : 0);

                              String statusText = '';
                              Color statusColor = Colors.black;

                              switch (app.status) {
                                case -1:
                                  statusText = 'Rejected';
                                  statusColor = Colors.red;
                                  break;
                                case 0:
                                  statusText = 'Pending';
                                  statusColor = Colors.orange;
                                  break;
                                case 1:
                                  statusText = 'Approved';
                                  statusColor = Colors.green;
                                  break;
                                default:
                                  statusText = 'Canceled';
                                  statusColor = Colors.grey;
                                  break;
                              }

                              return Column(
                                children: [
                                  Material(
                                    elevation: 2.0,
                                    child: GestureDetector(
                                      onTap: () {
                                        _showShiftDetailsDialog(app);
                                      },
                                      child: Container(
                                        width: context.width(),
                                        padding: const EdgeInsets.all(10.0),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            left: BorderSide(
                                              color:
                                                  getBorderColor(app.shiftName),
                                              width: 3.0,
                                            ),
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  app.shiftName ?? "",
                                                  maxLines: 2,
                                                  style: kTextStyle.copyWith(
                                                    color: kTitleColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '$formattedCrHour ago',
                                                  style: kTextStyle.copyWith(
                                                    color: kGreyTextColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'Date Work: $formattedDateWork',
                                              style: kTextStyle.copyWith(
                                                color: kGreyTextColor,
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Name: ${app.employeeName}',
                                                    maxLines: 2,
                                                    style: kTextStyle.copyWith(
                                                      color: kGreyTextColor,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  statusText,
                                                  style: kTextStyle.copyWith(
                                                    color: statusColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20.0),
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
