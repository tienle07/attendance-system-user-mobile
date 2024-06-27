// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:staras_mobile/common/toast.dart';
import 'package:staras_mobile/constants/api_consts.dart';
import 'package:staras_mobile/constants/constant.dart';
import 'package:staras_mobile/core/controllers/api_client.dart';
import 'package:staras_mobile/core/controllers/check_expired_token.dart';
import 'package:staras_mobile/model/shift/employee.shift.history.dart';
import 'package:staras_mobile/model/store/dropdown.store.model.dart';
import 'package:staras_mobile/widgets/dropdown.store.in.schedule.dart';

class EmployeeShiftCalendar extends StatefulWidget {
  const EmployeeShiftCalendar({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _EmployeeShiftCalendarState createState() => _EmployeeShiftCalendarState();
}

class _EmployeeShiftCalendarState extends State<EmployeeShiftCalendar> {
  List<EmployeeShiftHistory> applicationHistory = [];
  List<EmployeeShiftHistory> filteredApplicationHistory = [];
  List<EmployeeShiftHistory> selectedShifts = [];
  bool isShiftSelected = false;
  bool _isCancelButtonPressed = false;
  TextEditingController note = TextEditingController();
  DateTime? _selectedDate;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    checkTokenExpiration();
    _getDropdownStoreInShiftItems();
    filterShiftsByDate();
    _setDefaultValues();

    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      fetchAndFilterShiftHistoryData();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> checkTokenExpiration() async {
    final String? accessToken = await readAccessToken();
    if (mounted) {
      await AuthManager.checkTokenExpiration(accessToken!, context);
      if (_selectedStore != null) {
        fetchShiftHistoryData(_selectedStore!.storeId!);
        filterShiftsByDate();
      }
    }
  }

  Future<void> fetchAndFilterShiftHistoryData() async {
    if (_selectedStore != null) {
      await fetchShiftHistoryData(_selectedStore!.storeId);
      filterShiftsByDate();
    }
  }

  List<DropdownStore>? _dropdownStores;
  DropdownStore? _selectedStore;

  void _onDropdownStoreInScheduleSelected(DropdownStore? selectedStore) {
    setState(() {
      _selectedStore = selectedStore!;
      fetchShiftHistoryData(selectedStore.storeId);
    });
  }

  Future<void> fetchShiftHistoryData(int? storeId) async {
    final String? accessToken = await readAccessToken();
    final String? employeeId = await readEmployeeId();

    var apiUrl =
        '$BASE_URL/api/employeeshifthistory/get-employee-shift-histories?StoreId=$storeId&EmployeeId=$employeeId';

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

          final List<EmployeeShiftHistory> appHistory = shiftHistoryData
              .map((json) => EmployeeShiftHistory.fromJson(json))
              .where((shift) => shift.processingStatus != -2)
              .toList();

          setState(() {
            applicationHistory = appHistory;
          });
          filterShiftsByDate();
        } else {
          'Response StatusCode : ${response.statusCode} - ${response.body}';
          setState(() {
            applicationHistory = [];
            filteredApplicationHistory = [];
          });
        }
      } else if (response.statusCode == 204) {
        print(
            'Response StatusCode is 204 : ${response.statusCode} - ${response.body}');
        setState(() {
          applicationHistory = [];
          filteredApplicationHistory = [];
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  Future<void> updateShiftProcessingStatus(
    List<EmployeeShiftHistory> selectedShifts,
    String? note,
  ) async {
    final String? accessToken = await readAccessToken();

    try {
      final List<Future<void>> updateRequests =
          selectedShifts.map((shift) async {
        var apiUrl =
            '$BASE_URL/api/employeeshifthistory/employee-apply-many-leave-requests';
        final List<dynamic> requestBody = [
          {
            "employeeShiftHistoryId": shift.id,
            "note": note,
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

        if (response.statusCode >= 400 && response.statusCode <= 500) {
          final Map<String, dynamic> responseBody = jsonDecode(response.body);
          final String errorMessage = responseBody['message'];

          print(
              'Failed to update shift ${shift.id}. Status code: ${response.statusCode}');
          selectedShifts.clear();
          showToast(
            context: context,
            msg: errorMessage,
            color: Colors.red,
            icon: const Icon(Icons.error),
          );
        }
        print('Response body: ${response.body}');
        if (response.statusCode == 201) {
          print("Leave Request successful");

          showToast(
            context: context,
            msg: "Leave Request successful",
            color: Color.fromARGB(255, 128, 249, 16),
            icon: const Icon(Icons.done),
          );
          if (_selectedStore != null) {
            fetchShiftHistoryData(_selectedStore!.storeId);
          }

          selectedShifts.clear();
          cancelShifts();
          fetchShiftHistoryData(_selectedStore!.storeId!);
          filterShiftsByDate();
        } else {
          print(
              'Failed to update shift ${shift.id}. Status code: ${response.statusCode}');
          // showToast(
          //   context: context,
          //   msg: "Leave Request Not Successful",
          //   color: Colors.red,
          //   icon: const Icon(Icons.error),
          // );
          print('Response body: ${response.body}');
        }
      }).toList();

      await Future.wait(updateRequests);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating shifts: $e');
      }
    }
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
            fetchShiftHistoryData(_selectedStore!.storeId);
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

  void toggleShiftSelection(EmployeeShiftHistory shift) {
    setState(() {
      if (selectedShifts.contains(shift)) {
        selectedShifts.remove(shift);
      } else {
        selectedShifts.add(shift);
      }
      isShiftSelected = selectedShifts.isNotEmpty;
    });
  }

  void _setDefaultValues() {
    setState(() {
      _selectedDate = DateTime.now();
      filterShiftsByDate();
    });
  }

  void cancelShifts() {
    setState(() {
      _isCancelButtonPressed = false;
      selectedShifts.clear();
    });

    _updateButtonTextAndCheckbox();
  }

  void _updateButtonTextAndCheckbox() {
    setState(() {
      // Check if there are selected shifts and update the button text accordingly
      isShiftSelected = selectedShifts.isNotEmpty;

      // If the cancel button was pressed, update the text to 'Cancel'
      if (_isCancelButtonPressed) {
        if (isShiftSelected) {
          _isCancelButtonPressed = true;
        } else {
          _isCancelButtonPressed = false;
        }
      }
    });
  }

  void filterShiftsByDate() {
    if (_selectedDate != null) {
      filteredApplicationHistory = applicationHistory
          .where((shift) =>
              shift.startTime?.year == _selectedDate!.year &&
              shift.startTime?.month == _selectedDate!.month &&
              shift.startTime?.day == _selectedDate!.day)
          .toList();
    }
  }

  EasyDateTimeLine _changeDayStructureExample() {
    return EasyDateTimeLine(
      initialDate: DateTime.now(),
      onDateChange: (selectedDate) {
        setState(() {
          _selectedDate = selectedDate;
        });
        filterShiftsByDate();
      },
      activeColor: const Color(0xffE1ECC8),
      headerProps: const EasyHeaderProps(
        monthPickerType: MonthPickerType.switcher,
        selectedDateFormat: SelectedDateFormat.fullDateDMY,
      ),
      dayProps: const EasyDayProps(
        height: 56.0,
        width: 56.0,
        dayStructure: DayStructure.dayNumDayStr,
        inactiveDayStyle: DayStyle(
          borderRadius: 48.0,
          dayNumStyle: TextStyle(
            fontSize: 18.0,
          ),
        ),
        activeDayStyle: DayStyle(
          dayNumStyle: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: kMainColor,
      appBar: AppBar(
        backgroundColor: kMainColor,
        elevation: 0.0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Work Schedule Employee',
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
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0)),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 20.0,
                  ),
                  Container(
                    height: 170,
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: _changeDayStructureExample(),
                  ),
                  Container(
                    padding: EdgeInsets.all(15),
                    child: Row(
                      // Use a Column instead of Row
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownStoreInScheduleItems(
                          onItemSelectedStoreInSchedule:
                              _onDropdownStoreInScheduleSelected,
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              bool hasInvalidShifts =
                                  filteredApplicationHistory.every((shift) =>
                                      shift.processingStatus == -1 ||
                                      shift.processingStatus == 2);
                              if (hasInvalidShifts) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.warning,
                                          color: Colors.white,
                                        ),
                                        SizedBox(
                                            width:
                                                8.0), // Adjust the spacing between the icon and text
                                        Text('No Shift to Cancel',
                                            style: kTextStyle.copyWith(
                                                fontSize: 15,
                                                color: kDarkWhite)),
                                      ],
                                    ),
                                    backgroundColor: kMainColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    action: SnackBarAction(
                                      label: 'OK',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        // Handle action press if needed
                                      },
                                    ),
                                  ),
                                );
                                print(
                                    "Cannot perform action on shifts with status -1 or 2");
                              } else if (isShiftSelected) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return StatefulBuilder(
                                      builder: (context, setState) {
                                        List<Widget> shiftContainers =
                                            selectedShifts.map((shift) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            padding: EdgeInsets.all(16.0),
                                            margin:
                                                EdgeInsets.only(bottom: 16.0),
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
                                                      "Shift: ${shift.shiftName}",
                                                      style:
                                                          kTextStyle.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.close,
                                                          color: Colors.red),
                                                      onPressed: () {
                                                        // Remove the shift from the selected shifts list
                                                        toggleShiftSelection(
                                                            shift);
                                                        // Trigger a rebuild of the dialog
                                                        setState(() {});
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  "Start Time: ${DateFormat('hh:mm a').format(shift.startTime!)}",
                                                  style: kTextStyle,
                                                ),
                                                Text(
                                                  "End Time: ${DateFormat('hh:mm a').format(shift.endTime!)}",
                                                  style: kTextStyle,
                                                ),
                                                Text(
                                                  "Store Name: ${shift.storeName}",
                                                  style: kTextStyle,
                                                ),
                                                Text(
                                                  "Date: ${DateFormat('dd/MM/yyyy').format(shift.startTime!)}",
                                                  style: kTextStyle,
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList();

                                        return Dialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          backgroundColor: kDarkWhite,
                                          child: SingleChildScrollView(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Leave Request",
                                                    style: kTextStyle.copyWith(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 16),
                                                  Text(
                                                    "Are you sure you want to cancel the following shift(s)?",
                                                    style: kTextStyle.copyWith(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  SizedBox(height: 20),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: shiftContainers,
                                                  ),
                                                  SizedBox(height: 25),
                                                  TextFormField(
                                                    controller: note,
                                                    style: kTextStyle.copyWith(
                                                        fontSize: 15,
                                                        color: Colors.black),
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          'Note(Optional)',
                                                      labelStyle: kTextStyle,
                                                      hintStyle:
                                                          kTextStyle.copyWith(
                                                              fontSize: 15),
                                                      floatingLabelBehavior:
                                                          FloatingLabelBehavior
                                                              .always,
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(30),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 20),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              kAlertColor,
                                                        ),
                                                        child: Text(
                                                          'No',
                                                          style: kTextStyle
                                                              .copyWith(
                                                                  color: Colors
                                                                      .white),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 20,
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () async {
                                                          await updateShiftProcessingStatus(
                                                              selectedShifts,
                                                              note.text);
                                                          note.clear();

                                                          Navigator.of(context)
                                                              .pop();
                                                          fetchShiftHistoryData(
                                                              _selectedStore!
                                                                  .storeId);
                                                          filterShiftsByDate();
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              kMainColor,
                                                        ),
                                                        child: Text(
                                                          'Yes',
                                                          style: kTextStyle
                                                              .copyWith(
                                                                  color: Colors
                                                                      .white),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              } else if (filteredApplicationHistory.isEmpty ||
                                  filteredApplicationHistory.every(
                                      (shift) => shift.leaveRequest == true)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.warning,
                                          color: Colors.white,
                                        ),
                                        SizedBox(
                                            width:
                                                8.0), // Adjust the spacing between the icon and text
                                        Text('No Shift to Cancel',
                                            style: kTextStyle.copyWith(
                                                fontSize: 15,
                                                color: kDarkWhite)),
                                      ],
                                    ),
                                    backgroundColor: kMainColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    action: SnackBarAction(
                                      label: 'OK',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        // Handle action press if needed
                                      },
                                    ),
                                  ),
                                );
                              } else {
                                _isCancelButtonPressed =
                                    !_isCancelButtonPressed;
                                if (!_isCancelButtonPressed) {
                                  selectedShifts.clear();
                                }
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCancelButtonPressed &&
                                    filteredApplicationHistory.isNotEmpty &&
                                    !filteredApplicationHistory.every((shift) =>
                                        shift.leaveRequest == true ||
                                        shift.processingStatus == -1 ||
                                        shift.processingStatus == 2)
                                ? kMainColor
                                : Colors.white,
                          ),
                          child: Text(
                            isShiftSelected ? 'Continue' : 'Cancel',
                            style: kTextStyle.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      height: screenHeight * 0.8,
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: SingleChildScrollView(
                        child: _buildShiftCards(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftCards() {
    if (filteredApplicationHistory == null ||
        filteredApplicationHistory.isEmpty) {
      return Container(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.only(top: 150),
          child: Text('No shifts for today',
              style: kTextStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              )),
        ),
      );
    }
    return ListView.builder(
      itemCount: filteredApplicationHistory.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final shift = filteredApplicationHistory[index];

        String statusText = '';
        Color statusColor = Colors.black;

        switch (shift.processingStatus) {
          case -1:
            statusText = 'Absent';
            statusColor = Colors.red;
            break;
          case 1:
            statusText = 'Ready';
            statusColor = Colors.orange;
            break;
          case 2:
            statusText = 'Finished';
            statusColor = Colors.green;
            break;
          default:
            // Handle other cases if needed
            break;
        }

        return GestureDetector(
          onTap: () {
            if (_isCancelButtonPressed && !(shift.leaveRequest ?? false)) {
              toggleShiftSelection(shift);
            }
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 25),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 15,
                      height: 10,
                      decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(5),
                          )),
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width - 90,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                                text:
                                    '${DateFormat('hh:mm').format(shift.startTime!)}',
                                style: kTextStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      const Color.fromARGB(255, 124, 115, 115),
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        ' ${DateFormat('a').format(shift.startTime!)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      color: Colors.grey,
                                    ),
                                  )
                                ]),
                          ),
                          Text(
                            shift.duration ?? '',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.grey),
                    borderRadius: BorderRadius.circular(20),
                    color: (shift.leaveRequest == true)
                        ? (shift.requestStatus == 0
                            ? Colors.orange[100]
                            : (shift.requestStatus == -1
                                ? Colors.red[100]
                                : Colors.white))
                        : Colors.white,
                  ),
                  margin: EdgeInsets.only(right: 10, left: 20),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            shift.shiftName ?? '',
                            style: kTextStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (shift.processingStatus != -1 &&
                              shift.processingStatus != 2)
                            _isCancelButtonPressed &&
                                    !(shift.leaveRequest ?? false)
                                ? Checkbox(
                                    value: selectedShifts.contains(shift),
                                    onChanged: (_) {
                                      toggleShiftSelection(shift);
                                    },
                                  )
                                : Container(),
                        ],
                      ),
                      Text(
                        '$statusText',
                        style: kTextStyle.copyWith(
                            fontSize: 14, color: statusColor),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.store_mall_directory_outlined,
                            size: 20,
                            color: kMainColor,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Flexible(
                            child: Text(
                              "StoreName : ${shift.storeName ?? ''}",
                              maxLines: 2,
                              style: kTextStyle.copyWith(fontSize: 14),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.access_alarm_outlined,
                            size: 20,
                            color: kMainColor,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Time: ${DateFormat('hh:mm a').format(shift.startTime!)} - ${DateFormat('hh:mm a').format(shift.endTime!)} ',
                                  style: kTextStyle.copyWith(fontSize: 14)),
                              SizedBox(
                                height: 5,
                              ),
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 20,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Flexible(
                            child: Text(
                              "Address: ${shift.storeAddress ?? ''}",
                              style: kTextStyle.copyWith(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.access_time_filled_outlined,
                            size: 20,
                            color: shift.checkIn != null
                                ? Colors.orange
                                : Colors.black,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CheckIn : ${shift.checkIn != null ? DateFormat('hh:mm a').format(shift.checkIn!) : 'NotYet'}',
                                style: kTextStyle.copyWith(fontSize: 14),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.access_time_filled_outlined,
                            size: 20,
                            color: shift.checkOut != null
                                ? Colors.orange
                                : Colors.black,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CheckOut : ${shift.checkOut != null ? DateFormat('hh:mm a').format(shift.checkOut!) : 'NotYet'}',
                                style: kTextStyle.copyWith(fontSize: 14),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
