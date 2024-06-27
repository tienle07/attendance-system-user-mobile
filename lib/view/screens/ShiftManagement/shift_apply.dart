// ignore_for_file: unused_local_variable, library_private_types_in_public_api, prefer_const_constructors

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:intl/intl.dart';
import 'package:staras_mobile/animation/FadeAnimation.dart';
import 'package:staras_mobile/common/toast.dart';
import 'package:staras_mobile/components/button_global.dart';
import 'package:staras_mobile/constants/api_consts.dart';
import 'package:staras_mobile/constants/constant.dart';
import 'package:staras_mobile/core/controllers/api_client.dart';
import 'package:staras_mobile/core/controllers/check_expired_token.dart';
import 'package:staras_mobile/model/application/application.request.model.dart';
import 'package:staras_mobile/model/employee/employee.shift.model.dart';
import 'package:staras_mobile/model/store/dropdown.store.model.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:staras_mobile/widgets/dropdown.store.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ShiftApply extends StatefulWidget {
  final Function()? onRegisterShiftSuccess;
  const ShiftApply({Key? key, this.onRegisterShiftSuccess}) : super(key: key);

  @override
  State<ShiftApply> createState() => _ShiftApplyState();
}

class _ShiftApplyState extends State<ShiftApply> {
  ItemScrollController _scrollController = ItemScrollController();
  DropdownStore? _selectedStore;
  Set<int> _selectedDays = {};
  List<EmployeeShiftModel> shift = [];
  List<DateTime?> _selectedHours = [];
  bool showSelectDayAndHour = false;
  List<DateTime> nextWeekDays = [];
  final List<dynamic> _days = [];

  @override
  void initState() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _scrollController.scrollTo(
        index: 24,
        duration: const Duration(seconds: 3),
        curve: Curves.easeInOutCubic,
      );
    });
    nextWeekDays = getNextWeekDays();

    checkTokenExpiration();
    super.initState();
  }

  Future<void> checkTokenExpiration() async {
    final String? accessToken = await readAccessToken();
    if (mounted) {
      await AuthManager.checkTokenExpiration(accessToken!, context);
    }
  }

  void _onDropdownStoreSelected(DropdownStore? selectedStore) {
    setState(() {
      _selectedStore = selectedStore;
      showSelectDayAndHour = true;
      _fetchShiftWorkData(selectedStore?.storeId);
    });
  }

  void _resetSelection() {
    setState(() {
      _selectedDays.clear();
      _selectedHours.clear();
    });
  }

  Future<void> _sendApplication() async {
    try {
      List<int> shiftIds = _selectedHours
          .map((hour) =>
              shift
                  .firstWhere(
                      (shiftItem) => shiftItem.workShift?.startTime == hour)
                  .workShift
                  ?.id ??
              0)
          .toList();
      ApplicationRequestModel applicationRequest = ApplicationRequestModel(
        storeId: _selectedStore?.storeId,
        workShifts: shiftIds,
      );

      print(applicationRequest.toJson());

      var response = await httpPost('/api/employeeshift/work-registration',
          applicationRequest.toJson(), context);

      print(response);
      print(applicationRequest.toJson());

      var bodyResponse = jsonDecode(response['body']);
      if (bodyResponse['code'] == 201) {
        print("Application submitted successfully");
        // ignore: use_build_context_synchronously
        showToast(
          context: context,
          msg: "Register Shift Successfully",
          color: Color.fromARGB(255, 128, 249, 16),
          icon: const Icon(Icons.done),
        );
        _resetSelection();
        _fetchShiftWorkData(_selectedStore?.storeId);
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        if (widget.onRegisterShiftSuccess != null) {
          widget.onRegisterShiftSuccess!();
        }
      } else {
        print("Failed to submit application");

        showToast(
          context: context,
          msg: "Register Shift Not Success",
          color: Colors.red,
          icon: const Icon(Icons.error),
        );
      }
    } catch (error) {
      // ignore: use_build_context_synchronously
      showToast(
        context: context,
        msg: "Need fill all blank",
        color: Color.fromARGB(255, 255, 213, 149),
        icon: const Icon(Icons.warning),
      );
      print('Error: $error');
    }
  }

  void _fetchShiftWorkData(
    int? storeId,
  ) async {
    try {
      final String? accessToken = await readAccessToken();
      final String? employeeId = await readEmployeeId();
      final response = await http.get(
        Uri.parse(
            '$BASE_URL/api/workshift/get-employee-available-shifts?EmployeeId=$employeeId&storeId=$storeId'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'];

        if (data != null) {
          List<EmployeeShiftModel> shiftWorkList =
              data.map((item) => EmployeeShiftModel.fromJson(item)).toList();

          setState(() {
            shift = shiftWorkList;
          });
        } else {
          print('Data is null or not in the expected format');
        }
      } else if (response.statusCode == 204) {
        print('Failed to load shift work data');
        setState(() {
          shift = [];
        });
        print(response.statusCode);
        print(response.body);
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  void _showShiftInfoDialog() {
    if (_selectedHours.isEmpty) {
      // No shift item selected, show a message or perform any action
      showToast(
        context: context,
        msg: "Select at least one shift to register.",
        color: Colors.red,
        icon: const Icon(Icons.error),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                20.0), // Adjust the border radius as needed
            side: BorderSide(color: kMainColor, width: 2.0), // Add border side
          ),
          title: Text(
            "Are you sure you want to register for the shifts below?",
            style: kTextStyle,
          ),
          content: IntrinsicHeight(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: _selectedHours.map((hour) {
                  final selectedShift = shift.firstWhere(
                    (shiftItem) => shiftItem.workShift?.startTime == hour,
                    orElse: () => EmployeeShiftModel(),
                  );

                  return ListTile(
                    title: RichText(
                      text: TextSpan(
                        style: kTextStyle, // Default style for the entire text
                        children: [
                          TextSpan(
                            text:
                                '${selectedShift.workShift?.shiftName ?? ""} ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          TextSpan(
                            text:
                                '(${DateFormat('HH:mm').format(selectedShift.workShift?.startTime ?? DateTime.now())} - ${DateFormat('HH:mm').format(selectedShift.workShift?.endTime ?? DateTime.now())})',
                            style: TextStyle(fontSize: 17),
                          ),
                        ],
                      ),
                    ),
                    subtitle: Text(
                      'Day: ${DateFormat('EEEE, d MMMM').format(selectedShift.workShift?.startTime ?? DateTime.now())}',
                      style: kTextStyle,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        kAlertColor, // Background color for the "No" button
                  ),
                  child: Text(
                    'No',
                    style: kTextStyle.copyWith(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _sendApplication();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        kMainColor, // Background color for the "Yes" button
                  ),
                  child: Text(
                    'Yes',
                    style: kTextStyle.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool isFullDay = true;

  List<DateTime> getNextWeekDays() {
    final today = DateTime.now();
    final daysUntilMonday =
        DateTime.daysPerWeek - today.weekday + DateTime.monday;
    final nextMonday = today.add(Duration(days: daysUntilMonday));

    final nextWeekDays = List.generate(7, (index) {
      return nextMonday.add(Duration(days: index));
    });

    return nextWeekDays;
  }

  List<EmployeeShiftModel> filteredShiftItems(Set<int> selectedDays) {
    return shift.where((item) {
      return selectedDays.contains(item.workShift?.startTime?.day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    double containerHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: kMainColor,
      appBar: AppBar(
        backgroundColor: kMainColor,
        elevation: 0.0,
        titleSpacing: 0.0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Work Registration',
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
              height: containerHeight,
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0)),
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
                        Icons.calendar_month_outlined,
                      ),
                      SizedBox(width: 15.0),
                      Text(
                        "Register Shift",
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
                  DropdownStoreItems(
                      onItemSelectedStore: _onDropdownStoreSelected),
                  const SizedBox(
                    height: 20.0,
                  ),
                  if (showSelectDayAndHour)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10.0),
                        Text(
                          'Today: ${DateFormat('EEE, d MMMM y').format(DateTime.now())}',
                          style: kTextStyle.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 30.0),
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                            border: Border.all(
                              width: 1.5,
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: nextWeekDays.length,
                            itemBuilder: (BuildContext context, int index) {
                              final day = nextWeekDays[index];
                              final formattedDate = DateFormat('E').format(day);
                              final dayLabel = day.day.toString();
                              final uniqueKey = '${day.day}-$formattedDate';

                              final isSelected =
                                  _selectedDays.contains(day.day);

                              // Check if the day has a shift
                              final hasShift = shift.any(
                                (shiftItem) =>
                                    shiftItem.workShift?.startTime?.day ==
                                        day.day &&
                                    _selectedDays.contains(day.day),
                              );

                              return FadeAnimation(
                                (1 + index) / 6,
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (_selectedDays.contains(day.day)) {
                                        _selectedDays.remove(day.day);
                                      } else {
                                        _selectedDays.clear();
                                        _selectedDays.add(day.day);
                                      }
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    width: 62,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: hasShift
                                          ? Colors.orange[300]
                                          : Colors.blue.withOpacity(0),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.white.withOpacity(0),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          dayLabel,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          formattedDate,
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 50),
                        // Replace the existing ScrollablePositionedList.builder with this code

                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                            border: Border.all(
                              width: 1.5,
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: shift.length,
                            itemBuilder: (BuildContext context, int index) {
                              final shiftItem = shift[index];
                              final isSelected = _selectedHours
                                  .contains(shiftItem.workShift?.startTime);

                              // Filter shift items based on the selected days
                              if (!_selectedDays.contains(
                                  shiftItem.workShift?.startTime?.day)) {
                                return SizedBox
                                    .shrink(); // Skip this item if the day is not selected
                              }

                              void toggleHourSelection() {
                                setState(() {
                                  if (isSelected) {
                                    _selectedHours
                                        .remove(shiftItem.workShift?.startTime);
                                  } else {
                                    _selectedHours
                                        .add(shiftItem.workShift?.startTime);
                                  }
                                });
                              }

                              return Container(
                                margin: const EdgeInsets.only(
                                    right: 10.0), // Adjust margin as needed
                                child: GestureDetector(
                                  onTap: toggleHourSelection,
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    width: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: isSelected
                                          ? Colors.orange.shade100
                                              .withOpacity(0.5)
                                          : Colors.orange.withOpacity(0),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.orange
                                            : Colors.white.withOpacity(0),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                            '${shiftItem.workShift?.shiftName ?? ""}',
                                            style: kTextStyle.copyWith(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                          '${shiftItem.workShift?.startTime?.hour.toString().padLeft(2, '0')}:${shiftItem.workShift?.startTime?.minute.toString().padLeft(2, '0')} - ${shiftItem.workShift?.endTime?.hour.toString().padLeft(2, '0')}:${shiftItem.workShift?.endTime?.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 30),
                        if (_selectedHours.isNotEmpty)
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedHours.length,
                              itemBuilder: (BuildContext context, int index) {
                                final selectedShiftTime = _selectedHours[index];
                                final selectedShift = shift.firstWhere(
                                  (shiftItem) =>
                                      shiftItem.workShift?.startTime ==
                                      selectedShiftTime,
                                  orElse: () => EmployeeShiftModel(),
                                );

                                return Container(
                                  margin: const EdgeInsets.only(right: 10.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          kMainColor, // Choose your border color
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          ' ${DateFormat('EEEE, d MMMM').format(selectedShift.workShift?.startTime ?? DateTime.now())}',
                                          style: kTextStyle.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Start Time: ${DateFormat('HH:mm').format(selectedShift.workShift?.startTime ?? DateTime.now())}',
                                          style: kTextStyle.copyWith(
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'End Time: ${DateFormat('HH:mm').format(selectedShift.workShift?.endTime ?? DateTime.now())}',
                                          style: kTextStyle.copyWith(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ButtonGlobal(
                    buttontext: 'Register',
                    buttonDecoration:
                        kButtonDecoration.copyWith(color: kMainColor),
                    onPressed: () {
                      _showShiftInfoDialog();
                    },
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
