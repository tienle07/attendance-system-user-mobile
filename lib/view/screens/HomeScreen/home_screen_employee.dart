// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:staras_mobile/constants/api_consts.dart';
import 'package:staras_mobile/core/controllers/api_client.dart';
import 'package:staras_mobile/core/controllers/api_employee.dart';
import 'package:staras_mobile/core/controllers/check_expired_token.dart';
import 'package:staras_mobile/model/SidebarInfor/sidebar.infor.employee.model.dart';
import 'package:staras_mobile/model/employee/employee.profile.model.dart';
import 'package:staras_mobile/view/screens/Authentication/reset_password.dart';
import 'package:staras_mobile/view/screens/Authentication/sign_in_employee.dart';
import 'package:staras_mobile/view/screens/OvertimeApplication/overtime_list.dart';
import 'package:staras_mobile/constants/constant.dart';
import 'package:staras_mobile/view/screens/Authentication/profile_screen.dart';
import 'package:staras_mobile/view/screens/WorkInStore/list_work_store.dart';
import 'package:staras_mobile/view/screens/ShiftManagement/shift_management.dart';
import 'package:staras_mobile/view/screens/NoticeBoard/notice_list.dart';
import 'package:staras_mobile/view/screens/WorkScheduleEmployee/employee_shift_calender.dart';
import 'package:staras_mobile/view/screens/WorkScheduleEmployee/leave_application_request.dart';
import '../AttendanceManagement/management_screen.dart';

class HomeScreenEmployee extends StatefulWidget {
  const HomeScreenEmployee({
    Key? key,
  }) : super(key: key);

  @override
  _HomeScreenEmployeeState createState() => _HomeScreenEmployeeState();
}

class _HomeScreenEmployeeState extends State<HomeScreenEmployee> {
  EmployeeProfileModel? employeeProfile;
  InforSideBarEmployeeModel? inforSideBarEmployee;

  @override
  void initState() {
    super.initState();
    checkTokenExpiration();
  }

  Future<void> checkTokenExpiration() async {
    final String? accessToken = await readAccessToken();
    if (mounted) {
      await AuthManager.checkTokenExpiration(accessToken!, context);
      fetchDataProfileEmployee();
      fetchDataSideBar();
    }
  }

  Future<void> fetchDataProfileEmployee() async {
    final String? accessToken = await readAccessToken();

    final profile = await EmployeeApi.fetchProfile(accessToken);

    if (profile != null) {
      setState(() {
        employeeProfile = profile;
      });
    }
  }

  Future<void> fetchDataSideBar() async {
    try {
      final String? accessToken = await readAccessToken();
      final response = await http.get(
        Uri.parse('$BASE_URL/api/dashboard/get-employee-statistic'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        print(data);

        final InforSideBarEmployeeModel inforSideBarEmployeeData =
            InforSideBarEmployeeModel.fromJson(data['data']);
        print(inforSideBarEmployeeData.toString());
        setState(() {
          inforSideBarEmployee = inforSideBarEmployeeData;
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      // Handle other errors, e.g., network issues
      print('Error: $error');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: kMainColor,
        appBar: AppBar(
          backgroundColor: kMainColor,
          elevation: 0.0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 20.0,
              backgroundImage: NetworkImage(
                employeeProfile?.employeeResponse?.profileImage ?? "",
              ),
            ),
            title: Text(
              'Hi, ${employeeProfile?.employeeResponse?.name ?? ''}',
              style: kTextStyle.copyWith(color: Colors.white, fontSize: 12.0),
            ),
            subtitle: Text(
              'Good Morning',
              style: kTextStyle.copyWith(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              Container(
                height: context.height() / 2.5,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30.0),
                      bottomRight: Radius.circular(30.0)),
                  color: kMainColor,
                ),
                child: Column(
                  children: [
                    Container(
                      height: context.height() / 4,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30.0),
                            bottomRight: Radius.circular(30.0)),
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 10.0,
                            ),
                            CircleAvatar(
                              radius: 60.0,
                              backgroundColor: kMainColor,
                              backgroundImage: NetworkImage(
                                employeeProfile
                                        ?.employeeResponse?.profileImage ??
                                    "",
                              ),
                            ),
                            const SizedBox(
                              height: 10.0,
                            ),
                            Text(
                              employeeProfile?.employeeResponse?.name ?? '',
                              style: kTextStyle.copyWith(
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Employee',
                              style: kTextStyle.copyWith(color: kGreyTextColor),
                            ),
                          ],
                        ).onTap(() {
                          const ProfileScreen().launch(context);
                        }),
                      ),
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.only(
                                  left: 15.0,
                                  right: 15.0,
                                  top: 10.0,
                                  bottom: 10.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(80.0),
                                border: Border.all(color: Colors.white),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withOpacity(0.6),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${inforSideBarEmployee?.totalMonthWorkDurationFinished ?? 0}',
                                    style: kTextStyle.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'hour',
                                    style: kTextStyle.copyWith(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 2.0,
                            ),
                            Text(
                              'Work',
                              style: kTextStyle.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.only(
                                  left: 15.0,
                                  right: 15.0,
                                  top: 10.0,
                                  bottom: 10.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(80.0),
                                border: Border.all(color: Colors.white),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withOpacity(0.6),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${inforSideBarEmployee?.totalMonthAttendanceAbsent ?? 0}',
                                    style: kTextStyle.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'times',
                                    style: kTextStyle.copyWith(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 2.0,
                            ),
                            Text(
                              'Absent',
                              style: kTextStyle.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.only(
                                  left: 15.0,
                                  right: 15.0,
                                  top: 10.0,
                                  bottom: 10.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(80.0),
                                border: Border.all(color: Colors.white),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withOpacity(0.6),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${inforSideBarEmployee?.totalMonthAttendanceNotOnTime ?? 0}',
                                    style: kTextStyle.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'times',
                                    style: kTextStyle.copyWith(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 2.0,
                            ),
                            Text(
                              'Late',
                              style: kTextStyle.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ListTile(
                onTap: () => const ProfileScreen().launch(context),
                title: Text(
                  'Employee Profile',
                  style: kTextStyle.copyWith(color: kTitleColor),
                ),
                leading: const Icon(
                  FeatherIcons.user,
                  color: kMainColor,
                ),
              ),
              ListTile(
                onTap: () => const ListWorkStore().launch(context),
                title: Text(
                  'Work Store',
                  style: kTextStyle.copyWith(color: kTitleColor),
                ),
                leading: const Icon(
                  Icons.store,
                  color: kMainColor,
                ),
              ),
              ListTile(
                onTap: () => const ResetPasswordScreen().launch(context),
                title: Text(
                  'Change Password',
                  style: kTextStyle.copyWith(color: kTitleColor),
                ),
                leading: const Icon(
                  FeatherIcons.key,
                  color: kMainColor,
                ),
              ),
              // ListTile(
              //   onTap: () => const NotificationScreen().launch(context),
              //   title: Text(
              //     'Notification',
              //     style: kTextStyle.copyWith(color: kTitleColor),
              //   ),
              //   leading: const Icon(
              //     FeatherIcons.bell,
              //     color: kMainColor,
              //   ),
              // ),
              ListTile(
                title: Text(
                  'Terms & Conditions',
                  style: kTextStyle.copyWith(color: kTitleColor),
                ),
                leading: const Icon(
                  Icons.info_outline,
                  color: kMainColor,
                ),
              ),
              ListTile(
                title: Text(
                  'Privacy Policy',
                  style: kTextStyle.copyWith(color: kTitleColor),
                ),
                leading: const Icon(
                  FeatherIcons.alertTriangle,
                  color: kMainColor,
                ),
              ),
              ListTile(
                title: Text(
                  'Logout',
                  style: kTextStyle.copyWith(color: kTitleColor),
                ),
                leading: const Icon(
                  FeatherIcons.logOut,
                  color: kMainColor,
                ),
                onTap: () async {
                  await deleteAccessToken();
                  await deleteRefreshToken();

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SignInEmployee()),
                  );
                },
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 20.0,
              ),
              Container(
                height: 700,
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
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            const EmployeeManagement().launch(context);
                          },
                          child: Container(
                            width: 165,
                            height: 150,
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  stops: [0.02, 0.02],
                                  colors: [kMainColor, Colors.white]),
                              borderRadius: BorderRadius.circular(15.0),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 3,
                                  blurRadius: 5,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5, left: 15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Image(
                                      image: AssetImage(
                                          'images/employeeattendace.png')),
                                  Text(
                                    'Employee',
                                    style: kTextStyle.copyWith(
                                        color: kTitleColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Attendance',
                                    style: kTextStyle.copyWith(
                                        color: kTitleColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 20.0,
                        ),
                        GestureDetector(
                          onTap: () {
                            EmployeeShiftCalendar().launch(context);
                          },
                          child: Container(
                            width: 165,
                            height: 150,
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  stops: [0.02, 0.02],
                                  colors: [kMainColor, Colors.white]),
                              borderRadius: BorderRadius.circular(15.0),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 3,
                                  blurRadius: 5,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5, left: 15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Image(
                                      image: AssetImage(
                                          'images/employeedirectory.png')),
                                  Text(
                                    'Employee',
                                    style: kTextStyle.copyWith(
                                        color: kTitleColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'TimeTable',
                                    style: kTextStyle.copyWith(
                                        color: kTitleColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            const LeaveManagementScreen().launch(context);
                          },
                          child: Container(
                            width: 165,
                            height: 150,
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  stops: [0.02, 0.02],
                                  colors: [kMainColor, Colors.white]),
                              borderRadius: BorderRadius.circular(
                                  15.0), // Adjust the radius as needed
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 3,
                                  blurRadius: 5,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5, left: 15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Image(
                                      image: AssetImage('images/leave.png')),
                                  Text(
                                    'Work',
                                    style: kTextStyle.copyWith(
                                        color: kTitleColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Registration',
                                    style: kTextStyle.copyWith(
                                        color: kTitleColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 20.0,
                        ),
                        GestureDetector(
                          onTap: () {
                            const LeaveApplicationRequest().launch(context);
                          },
                          child: Container(
                            width: 165,
                            height: 150,
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  stops: [0.02, 0.02],
                                  colors: [kMainColor, Colors.white]),
                              borderRadius: BorderRadius.circular(15.0),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 3,
                                  blurRadius: 5,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5, left: 15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Image(
                                      image:
                                          AssetImage('images/workreport.png')),
                                  Text(
                                    'Leave',
                                    maxLines: 2,
                                    style: kTextStyle.copyWith(
                                        color: kTitleColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Management',
                                    style: kTextStyle.copyWith(
                                        color: kTitleColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    const SizedBox(
                      height: 15.0,
                    ),
                    Container(
                      width: context.width(),
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            stops: [0.010, 0.010],
                            colors: [kMainColor, Colors.white]),
                        borderRadius: BorderRadius.circular(
                            15.0), // Adjust the radius as needed
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () => const NoticeList().launch(context),
                        leading: const Image(
                            image: AssetImage('images/noticeboard.png')),
                        title: Text(
                          'Notification',
                          maxLines: 2,
                          style: kTextStyle.copyWith(
                              color: kTitleColor, fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: kMainColor,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    Container(
                      width: context.width(),
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            stops: [0.010, 0.010],
                            colors: [kMainColor, Colors.white]),
                        borderRadius: BorderRadius.circular(
                            15.0), // Adjust the radius as needed
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () => const OvertimeList().launch(context),
                        leading: const Image(
                            image: AssetImage('images/outworksubmission.png')),
                        title: Text(
                          'Outwork Submission',
                          maxLines: 2,
                          style: kTextStyle.copyWith(
                              color: kTitleColor, fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: kMainColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // bottomNavigationBar: const BottomTab(),
      ),
    );
  }
}
