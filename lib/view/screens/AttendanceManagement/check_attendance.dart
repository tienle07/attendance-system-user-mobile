// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:staras_mobile/constants/constant.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:slider_button/slider_button.dart';
import 'package:staras_mobile/core/controllers/api_client.dart';
import 'package:staras_mobile/core/controllers/api_employee.dart';
import 'package:staras_mobile/model/employee/employee.profile.model.dart';
import 'package:staras_mobile/view/camera_view/camera_view.dart';
import 'package:one_clock/one_clock.dart';

class CheckAttendance extends StatefulWidget {
  const CheckAttendance({Key? key}) : super(key: key);

  @override
  _CheckAttendanceState createState() => _CheckAttendanceState();
}

class _CheckAttendanceState extends State<CheckAttendance> {
  DateTime dateTime = DateTime.now();
  bool isOffice = true;
  Position? _currentLocation;
  late bool servicePermission = false;
  late LocationPermission permission;
  bool isLocationChecked = false;
  EmployeeProfileModel? employeeProfile;

  String _currentAddress = "";

  @override
  void initState() {
    super.initState();
    fetchProfileEmployee();
  }

  Future<void> fetchProfileEmployee() async {
    final String? accessToken = await readAccessToken();

    final profile = await EmployeeApi.fetchProfile(accessToken);

    if (profile != null) {
      setState(() {
        employeeProfile = profile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    void _setNewDateTime(DateTime dateTiime) {
      setState(() {
        dateTime = dateTiime;
      });
    }

    //Hàm lấy vị trí
    Future<Position> _getCurrentPosition() async {
      servicePermission = await Geolocator.isLocationServiceEnabled();
      if (!servicePermission) {
        print("service disabled");
      }
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return await Geolocator.getCurrentPosition();
    }

    _getAddressFromCoordinates() async {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            _currentLocation!.latitude, _currentLocation!.longitude);
        print(_currentLocation!.latitude);
        print(_currentLocation!.longitude);
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress =
              "${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.administrativeArea}, ${place.country}";
          isLocationChecked = true;
        });

        print(place);
      } catch (e) {
        print(e);
      }
    }

    void _showAddressBottomSheet(BuildContext context, String address) {
      showModalBottomSheet<void>(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 370,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your Address',
                  style: kTextStyle.copyWith(
                      fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 30.0),
                Card(
                  elevation: 3, // Độ đổ bóng của card
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      address,
                      style: kTextStyle.copyWith(color: kGreyTextColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 100.0),
                SliderButton(
                  action: () {
                    Navigator.of(context).pop();
                  },
                  label: Text(
                    "Swipe right to Punch In",
                    style: kTextStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 48,
                  ),
                  width: 350,
                  radius: 40,
                  buttonColor: Colors.green,
                  backgroundColor: Colors.grey,
                  highlightedColor: Colors.green,
                ),
              ],
            ),
          );
        },
      );
    }

    void _showLocationBottomSheet(BuildContext context) {
      showModalBottomSheet<void>(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 370,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_location_rounded,
                      size: 100.0,
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Enable Your Location',
                  style: kTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'This app requires that location services are turned on on your device and for this app. You must enable them to use this app.',
                  style: kTextStyle.copyWith(color: kGreyTextColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () async {
                    _currentLocation = await _getCurrentPosition();
                    await _getAddressFromCoordinates();
                    Navigator.pop(context);
                    _showAddressBottomSheet(context, _currentAddress);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    minimumSize: const Size(320, 55),
                  ),
                  child: Text(
                    'Get Current Location',
                    style: kTextStyle.copyWith(
                      color: kDarkWhite,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    void _showStoreSelectionBottomSheet(BuildContext context) {
      showModalBottomSheet<void>(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select a Store',
                  style: kTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.store,
                      size: 50.0,
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                _buildStoreList(),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () {
                    // Handle store selection here
                    // After selecting a store, close this bottom sheet and show the location bottom sheet
                    Navigator.of(context).pop();
                    _showLocationBottomSheet(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    minimumSize: const Size(320, 55),
                  ),
                  child: Text(
                    'Select Store',
                    style: kTextStyle.copyWith(
                      color: kDarkWhite,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
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
            'Check Attendance',
            maxLines: 2,
            style: kTextStyle.copyWith(
              color: kDarkWhite,
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.white.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.history,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: context.width(),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0)),
                color: kBgColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: context.width(),
                    padding: const EdgeInsets.all(14.0),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30.0),
                        topRight: Radius.circular(30.0),
                      ),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Your Location:',
                              style: kTextStyle.copyWith(
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(
                              width: 4.0,
                            ),
                            Text(
                              isLocationChecked
                                  ? 'Location are checked!'
                                  : 'Location Not Found',
                              style: kTextStyle.copyWith(color: kGreyTextColor),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(6.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: kMainColor.withOpacity(0.1),
                              ),
                              child: const Icon(
                                Icons.rotate_right,
                                color: kMainColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        Row(
                          children: [
                            Text(
                              'Please, Click',
                              style: kTextStyle.copyWith(
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(
                              width: 4.0,
                            ),
                            Text(
                              ' button Check to start',
                              style: kTextStyle.copyWith(color: kGreyTextColor),
                            ),
                            const SizedBox(
                              width: 25.0, // Khoảng cách giữa văn bản và nút
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Hiển thị Bottom Sheet modal khi nút được nhấn
                                _showStoreSelectionBottomSheet(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kMainColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              child: const Text(
                                'Check',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: context.width(),
                    padding: const EdgeInsets.all(30.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Choose your Attendance mode',
                          style:
                              kTextStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        Container(
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.0),
                            color: kMainColor,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30.0),
                                  color: isOffice ? Colors.white : kMainColor,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: kMainColor,
                                      child: Icon(
                                        Icons.check,
                                        color: isOffice
                                            ? Colors.white
                                            : kMainColor,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 4.0,
                                    ),
                                    Text(
                                      'Check In',
                                      style: kTextStyle.copyWith(
                                        color: isOffice
                                            ? kTitleColor
                                            : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 12.0,
                                    ),
                                  ],
                                ),
                              ).onTap(() {
                                setState(() {
                                  isOffice = !isOffice;
                                });
                              }),
                              Container(
                                padding: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30.0),
                                  color: !isOffice ? Colors.white : kMainColor,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: kMainColor,
                                      child: Icon(
                                        Icons.check,
                                        color: !isOffice
                                            ? Colors.white
                                            : kMainColor,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 4.0,
                                    ),
                                    Text(
                                      'Check Out ',
                                      style: kTextStyle.copyWith(
                                        color: !isOffice
                                            ? kTitleColor
                                            : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 12.0,
                                    ),
                                  ],
                                ),
                              ).onTap(() {
                                setState(() {
                                  isOffice = !isOffice;
                                });
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 30.0,
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        Text(
                          DateFormat.yMMMMEEEEd().format(DateTime.now()),
                          style: kTextStyle.copyWith(color: kGreyTextColor),
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        DigitalClock.light(
                          isLive: true,
                          datetime: dateTime,
                          textScaleFactor: 1.3,
                        ),
                        const SizedBox(
                          height: 15.0,
                        ),
                        GestureDetector(
                          onTap: () {
                            // Navigate to the FaceDetectorView when the user taps on the CircleAvatar
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const CameraView()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100.0),
                              color: isOffice
                                  ? kGreenColor.withOpacity(0.1)
                                  : kAlertColor.withOpacity(0.1),
                            ),
                            child: CircleAvatar(
                              radius: 80.0,
                              backgroundColor:
                                  isOffice ? kGreenColor : kAlertColor,
                              child: Text(
                                isOffice ? 'Check In' : 'Check Out',
                                style: kTextStyle.copyWith(
                                    color: Colors.white,
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15.0),
                        const Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                // Biểu tượng cho trường "Check In"
                                Icon(Icons.access_alarm_outlined),
                                // Biểu tượng cho trường "Check Out"
                                Icon(Icons.access_time),
                                // Biểu tượng cho trường "Total Time"
                                Icon(Icons.access_time_filled_outlined),
                              ],
                            ),
                            SizedBox(
                              height: 20.0,
                            ),
                            // Hàng 1: Chứa ba trường "Check In", "Check Out", "Total Time"
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Trường "Check In"
                                Column(
                                  children: [
                                    Text('Check In',
                                        style: TextStyle(
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                // Trường "Check Out"
                                Column(
                                  children: [
                                    Text('Check Out',
                                        style: TextStyle(
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                // Trường "Total Time"
                                Column(
                                  children: [
                                    Text('Total Time',
                                        style: TextStyle(
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                // Giá trị cho trường "Check In"
                                Column(
                                  children: [
                                    Text('07:00',
                                        style: TextStyle(fontSize: 12.0)),
                                  ],
                                ),
                                // Giá trị cho trường "Check Out"
                                Column(
                                  children: [
                                    Text('10h:00',
                                        style: TextStyle(fontSize: 12.0)),
                                  ],
                                ),
                                // Giá trị cho trường "Total Time"
                                Column(
                                  children: [
                                    Text('03:00',
                                        style: TextStyle(fontSize: 12.0)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildStoreList() {
    if (employeeProfile?.storeList == null ||
        employeeProfile!.storeList!.isEmpty) {
      // Display a message if there are no stores available
      return Text('No stores available');
    } else {
      // Build the list of store items
      return Column(
        children: employeeProfile!.storeList!.map((store) {
          return ListTile(
            title: Text(store.storeName ?? ''),
            onTap: () {},
          );
        }).toList(),
      );
    }
  }
}
