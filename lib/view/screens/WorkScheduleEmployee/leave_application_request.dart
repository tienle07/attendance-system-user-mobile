// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:staras_mobile/constants/api_consts.dart';
import 'package:staras_mobile/constants/constant.dart';
import 'package:staras_mobile/core/controllers/api_client.dart';
import 'package:staras_mobile/core/controllers/check_expired_token.dart';
import 'package:staras_mobile/model/application/leave.application.model.dart';
import 'package:staras_mobile/model/store/dropdown.store.model.dart';
import 'package:staras_mobile/widgets/dropdown.store.in.leave.application.dart';

class LeaveApplicationRequest extends StatefulWidget {
  const LeaveApplicationRequest({
    Key? key,
  }) : super(key: key);

  @override
  _LeaveApplicationRequestState createState() =>
      _LeaveApplicationRequestState();
}

class _LeaveApplicationRequestState extends State<LeaveApplicationRequest> {
  List<LeaveApplicationModel> shiftHistory = [];
  List<String> types = ['All', 'Approved', 'Rejected', 'Canceled'];
  String selected = 'All';
  List<DropdownStore>? _dropdownStores;
  DropdownStore? _selectedStore;
  bool isApproved = false;
  bool isRequest = true;

  @override
  void initState() {
    super.initState();
    checkTokenExpiration();
  }

  Future<void> checkTokenExpiration() async {
    final String? accessToken = await readAccessToken();
    if (mounted) {
      await AuthManager.checkTokenExpiration(accessToken!, context);
      _getDropdownStores();
    }
  }

  void _onDropdownStoreInLeaveApplication(DropdownStore? selectedStore) {
    setState(() {
      _selectedStore = selectedStore!;
      fetchListLeaveApplication(selectedStore.storeId);
    });
  }

  void _getDropdownStores() async {
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
          _dropdownStores = data
              .where((item) => [2, 1, 0].contains(item['status']))
              .map((item) => DropdownStore.fromJson(item))
              .toList();

          _selectedStore =
              _dropdownStores?.isNotEmpty == true ? _dropdownStores![0] : null;

          fetchListLeaveApplication(_selectedStore?.storeId);
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

  Future<void> fetchListLeaveApplication(int? storeId,
      {int? requestStatus}) async {
    final String? accessToken = await readAccessToken();
    final String? employeeId = await readEmployeeId();

    var apiUrl =
        '$BASE_URL/api/employeeshifthistory/get-employee-shift-histories?StoreId=$storeId&EmployeeId=$employeeId&LeaveRequest=true';

    if (requestStatus != null) {
      apiUrl += '&RequestStatus=$requestStatus';
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

        print("Get Success: ${responseData}");

        if (responseData.containsKey('data')) {
          final List<dynamic> shiftHistoryData = responseData['data'];

          final List<LeaveApplicationModel> appHistory = shiftHistoryData
              .map((json) => LeaveApplicationModel.fromJson(json))
              .toList();

          setState(() {
            shiftHistory = appHistory;
          });
        } else {
          'Response StatusCode : ${response.statusCode} - ${response.body}';
          setState(() {
            shiftHistory = [];
          });
        }
      } else if (response.statusCode == 204) {
        print(
            'Response StatusCode is 204 : ${response.statusCode} - ${response.body}');
        setState(() {
          shiftHistory = [];
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  Map<String, int> calculateApplicationCounts() {
    int approvedCount =
        shiftHistory.where((app) => app.requestStatus == 1).length;
    int rejectedCount =
        shiftHistory.where((app) => app.requestStatus == -1).length;
    int canceledCount =
        shiftHistory.where((app) => app.requestStatus == -2).length;

    Map<String, int> counts = {
      'All': approvedCount + rejectedCount + canceledCount,
      'Approved': approvedCount,
      'Rejected': rejectedCount,
      'Canceled': canceledCount,
    };

    return counts;
  }

  Color? getStatusColor(int? status) {
    switch (status) {
      case 1:
        return Colors.green[100];
      case -1:
        return Colors.red[100];

      default:
        return Colors.transparent;
    }
  }

  String getStatusText(int? status) {
    switch (status) {
      case 1:
        return 'Approved';
      case -1:
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  int countPendingApplications() {
    return shiftHistory
        .where((application) => application.requestStatus == 0)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: kMainColor,
      appBar: AppBar(
        backgroundColor: kMainColor,
        elevation: 0.0,
        titleSpacing: 0.0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Leave Application',
          maxLines: 2,
          style: kTextStyle.copyWith(
            color: kDarkWhite,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: context.width(),
              height: screenHeight,
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0)),
                color: kBgColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MaterialButton(
                        onPressed: () {
                          setState(() {
                            isApproved = false;
                            isRequest = true;
                          });
                        },
                        height: 55,
                        minWidth: 160,
                        color: isApproved ? Colors.cyan[50] : kMainColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Request',
                              style: kTextStyle.copyWith(
                                color:
                                    isApproved ? kGreyTextColor : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${countPendingApplications()})',
                              style: kTextStyle.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color:
                                    isApproved ? kGreyTextColor : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      MaterialButton(
                        onPressed: () {
                          setState(() {
                            isApproved = true;
                            isRequest = false;
                          });
                        },
                        height: 55,
                        minWidth: 160,
                        color: isRequest ? Colors.cyan[50] : kMainColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Text(
                          'Response',
                          style: kTextStyle.copyWith(
                              color: isRequest ? kGreyTextColor : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  SizedBox(
                    width: 250,
                    child: DropdownStoreInLeaveApplication(
                      onItemSelectedStoreInLeaveApplication:
                          _onDropdownStoreInLeaveApplication,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30.0),
                        topRight: Radius.circular(30.0),
                      ),
                      color: Colors.white,
                    ),
                    child: isApproved
                        ? HorizontalList(
                            spacing: 0,
                            itemCount: types.length,
                            itemBuilder: (_, i) {
                              Map<String, int> counts =
                                  calculateApplicationCounts();
                              return Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text(
                                  '${types[i]} (${counts[types[i]]})',
                                  style: kTextStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: selected == types[i]
                                        ? kMainColor
                                        : kGreyTextColor,
                                  ),
                                ).onTap(() {
                                  setState(() {
                                    selected = types[i];
                                  });
                                }),
                              );
                            },
                          )
                        : Container(),
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  Expanded(
                    child: isRequest
                        ? shiftHistory
                                .where((application) =>
                                    application.leaveRequest == true &&
                                    application.requestStatus == 0)
                                .isEmpty
                            ? Container(
                                padding: const EdgeInsets.only(bottom: 100),
                                child: Center(
                                  child: Text(
                                    'No Leave Application!',
                                    style: kTextStyle.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: shiftHistory
                                      .where((application) =>
                                          application.leaveRequest == true &&
                                          application.requestStatus == 0)
                                      .map((application) {
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 20.0),
                                      child: Card(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ListTile(
                                                title: Row(
                                                  children: [
                                                    Text(
                                                      "Date: ",
                                                      style:
                                                          kTextStyle.copyWith(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      "${application.startTime != null ? DateFormat('d MMM, yyyy').format(application.startTime!) : 'Not Yet'}",
                                                      style:
                                                          kTextStyle.copyWith(
                                                              fontSize: 14),
                                                    ),
                                                  ],
                                                ),
                                                subtitle: Row(
                                                  children: [
                                                    Text(
                                                      // application.shiftName ?? '',
                                                      "Shift:  ",
                                                      style:
                                                          kTextStyle.copyWith(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      // pplication.shiftName ?? '',
                                                      "${application.shiftName ?? ''}",
                                                      style:
                                                          kTextStyle.copyWith(
                                                        color: kGreyTextColor,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                trailing: Container(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  height: 50,
                                                  width: 70,
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4.0),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      application.requestStatus ==
                                                              1
                                                          ? 'Approved'
                                                          : 'Pending',
                                                      style: kTextStyle.copyWith(
                                                          color:
                                                              kGreyTextColor),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Divider(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                thickness: 1,
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 15),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      "From: ",
                                                      style:
                                                          kTextStyle.copyWith(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      "  ${application.startTime != null ? DateFormat('hh:mm:a').format(application.startTime!) : ''}  ",
                                                      style:
                                                          kTextStyle.copyWith(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    Text(
                                                      "To: ",
                                                      style:
                                                          kTextStyle.copyWith(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      "  ${application.endTime != null ? DateFormat('hh:mm:a').format(application.endTime!) : ''}",
                                                      style:
                                                          kTextStyle.copyWith(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Divider(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                thickness: 1,
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 10, left: 15),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Note: ',
                                                      style: kTextStyle.copyWith(
                                                          color:
                                                              kBlackTextColor,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    const SizedBox(
                                                      height: 20.0,
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        application
                                                                .requestNote ??
                                                            "",
                                                        style:
                                                            kTextStyle.copyWith(
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 15.0),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              )
                        : isApproved
                            ? shiftHistory
                                    .where((application) =>
                                        (selected == 'All' &&
                                            (application.requestStatus == 1 ||
                                                application.requestStatus ==
                                                    -1 ||
                                                application.requestStatus ==
                                                    -2)) ||
                                        (selected == 'Approved' &&
                                            application.requestStatus == 1) ||
                                        (selected == 'Rejected' &&
                                            application.requestStatus == -1) ||
                                        (selected == 'Canceled' &&
                                            application.requestStatus == -2))
                                    .isEmpty
                                ? Container(
                                    padding: const EdgeInsets.only(bottom: 100),
                                    child: Center(
                                      child: Text(
                                        'No Leave Application!',
                                        style: kTextStyle.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: shiftHistory
                                          .where((application) =>
                                              (selected == 'All' &&
                                                  (application.requestStatus ==
                                                          1 ||
                                                      application
                                                              .requestStatus ==
                                                          -1 ||
                                                      application
                                                              .requestStatus ==
                                                          -2)) ||
                                              (selected == 'Approved' &&
                                                  application.requestStatus ==
                                                      1) ||
                                              (selected == 'Rejected' &&
                                                  application.requestStatus ==
                                                      -1) ||
                                              (selected == 'Canceled' &&
                                                  application.requestStatus ==
                                                      -2))
                                          .map((application) {
                                        return Container(
                                          margin: EdgeInsets.only(bottom: 20.0),
                                          child: Card(
                                            color: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  ListTile(
                                                    title: Row(
                                                      children: [
                                                        Text(
                                                          "Date: ",
                                                          style: kTextStyle
                                                              .copyWith(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          "${application.startTime != null ? DateFormat('d MMM, yyyy').format(application.startTime!) : 'Not Yet'}",
                                                          style: kTextStyle
                                                              .copyWith(
                                                                  fontSize: 14),
                                                        ),
                                                      ],
                                                    ),
                                                    subtitle: Row(
                                                      children: [
                                                        Text(
                                                          "Shift:  ",
                                                          style: kTextStyle
                                                              .copyWith(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          "${application.shiftName ?? ''}",
                                                          style: kTextStyle
                                                              .copyWith(
                                                            color:
                                                                kGreyTextColor,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    trailing: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      height: 50,
                                                      width: 80,
                                                      decoration: BoxDecoration(
                                                        color: getStatusColor(
                                                            application
                                                                .requestStatus),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4.0),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          application.requestStatus ==
                                                                  1
                                                              ? 'Approved'
                                                              : 'Rejected',
                                                          style: kTextStyle
                                                              .copyWith(
                                                                  color:
                                                                      kGreyTextColor),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Divider(
                                                    color: Colors.black
                                                        .withOpacity(0.2),
                                                    thickness: 1,
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 15),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          "From: ",
                                                          style: kTextStyle
                                                              .copyWith(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          "  ${application.startTime != null ? DateFormat('hh:mm:a').format(application.startTime!) : ''}  ",
                                                          style: kTextStyle
                                                              .copyWith(
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                        Text(
                                                          "To: ",
                                                          style: kTextStyle
                                                              .copyWith(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          "  ${application.endTime != null ? DateFormat('hh:mm:a').format(application.endTime!) : ''}",
                                                          style: kTextStyle
                                                              .copyWith(
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Divider(
                                                    color: Colors.black
                                                        .withOpacity(0.2),
                                                    thickness: 1,
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      top: 10,
                                                      left: 15,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          'Request: ',
                                                          style: kTextStyle
                                                              .copyWith(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                        ),
                                                        const SizedBox(
                                                          height: 20.0,
                                                        ),
                                                        Text(
                                                          "${application.requestDate != null ? DateFormat('d MMMM, yyyy').format(application.requestDate!) : 'Not Yet'}",
                                                          style: kTextStyle
                                                              .copyWith(
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      top: 10,
                                                      left: 15,
                                                    ),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start, // Align text to the top
                                                      children: [
                                                        Text(
                                                          'Note: ',
                                                          style: kTextStyle
                                                              .copyWith(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Flexible(
                                                          child: Text(
                                                            application
                                                                    .requestNote ??
                                                                "",
                                                            style: kTextStyle
                                                                .copyWith(
                                                                    fontSize:
                                                                        14),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      top: 10,
                                                      left: 15,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          'Approved: ',
                                                          style: kTextStyle
                                                              .copyWith(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                        ),
                                                        const SizedBox(
                                                          height: 20.0,
                                                        ),
                                                        Text(
                                                          "${application.approvalDate != null ? DateFormat('d MMMM, yyyy').format(application.approvalDate!) : 'Not Yet'}",
                                                          style: kTextStyle
                                                              .copyWith(
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      top: 10,
                                                      left: 15,
                                                    ),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start, // Align text to the top
                                                      children: [
                                                        Text(
                                                          'Note: ',
                                                          style: kTextStyle
                                                              .copyWith(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Flexible(
                                                          child: Text(
                                                            application
                                                                    .responseNote ??
                                                                "",
                                                            style: kTextStyle
                                                                .copyWith(
                                                                    fontSize:
                                                                        14),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  )
                            : Container(),
                  ),
                  const SizedBox(
                    height: 20,
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
