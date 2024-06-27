// ignore_for_file: depend_on_referenced_packages, library_private_types_in_public_api

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:staras_mobile/constants/api_consts.dart';
import 'package:staras_mobile/constants/constant.dart';
import 'package:staras_mobile/core/controllers/api_client.dart';
import 'package:staras_mobile/core/controllers/check_expired_token.dart';
import 'package:staras_mobile/model/application/list.shift.model.dart';

class ShiftDetailsPage extends StatefulWidget {
  final int id;
  const ShiftDetailsPage({Key? key, required this.id}) : super(key: key);

  @override
  _ShiftDetailsPageState createState() => _ShiftDetailsPageState();
}

class _ShiftDetailsPageState extends State<ShiftDetailsPage> {
  ShiftApplicationModel? applicationDetail;
  @override
  void initState() {
    super.initState();
    fetchShiftApplicationDetail();
    checkTokenExpiration();
  }

  Future<void> checkTokenExpiration() async {
    final String? accessToken = await readAccessToken();
    if (mounted) {
      await AuthManager.checkTokenExpiration(accessToken!, context);
      fetchShiftApplicationDetail();
    }
  }

  Future<void> fetchShiftApplicationDetail() async {
    const apiUrl = '$BASE_URL/api/employeeshift/get-registration-detail';

    final int applicationId = widget.id;

    final String? accessToken = await readAccessToken();

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/$applicationId'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        print('Succeed response: ${response.body}');

        if (responseData.containsKey('data')) {
          final Map<String, dynamic> applicationData = responseData['data'];

          final ShiftApplicationModel application =
              ShiftApplicationModel.fromJson(applicationData);

          setState(() {
            applicationDetail = application;
          });
        } else {
          print(
              'API Error: Response does not contain the expected data structure.');
        }
      } else {
        // ScaffoldMessenger.of(context).showSnackBar();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
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
          'View Registration',
          maxLines: 2,
          style: kTextStyle.copyWith(
              color: Colors.white, fontWeight: FontWeight.bold),
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
              width: context.width(),
              height: 2000,
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
                    height: 40.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.mail_outline_outlined,
                        ),
                        SizedBox(width: 15.0),
                        Text(
                          "Shift Details",
                          style: kTextStyle.copyWith(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 50.0,
                  ),
                  Center(
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.mail_lock_outlined,
                                color: kMainColor,
                              ),
                              title: Text(
                                applicationDetail?.shiftName ?? "",
                                style: kTextStyle.copyWith(
                                  fontSize: 17.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                applicationDetail?.employeeName ?? "",
                                style:
                                    kTextStyle.copyWith(color: kGreyTextColor),
                              ),
                            ),
                            Divider(
                              color: kMainColor.withOpacity(0.5),
                              thickness: 1,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Register Date: ${applicationDetail?.registerDate != null ? DateFormat('dd/MM/yyyy').format(applicationDetail!.registerDate!) : 'No'}',
                              style: kTextStyle.copyWith(color: kGreyTextColor),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Start time: ${DateFormat('HH:mm').format(applicationDetail?.startTime ?? DateTime.now())} h',
                              style: kTextStyle.copyWith(color: kGreyTextColor),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'End time: ${DateFormat('HH:mm').format(applicationDetail?.endTime ?? DateTime.now())} h',
                              style: kTextStyle.copyWith(color: kGreyTextColor),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'UpdateDate: ${applicationDetail?.updateDate != null ? DateFormat('dd/MM/yyyy').format(applicationDetail!.updateDate!) : 'No'}',
                              style: kTextStyle.copyWith(color: kGreyTextColor),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'ApprovalDate: ${applicationDetail?.approvalDate != null ? DateFormat('dd/MM/yyyy').format(applicationDetail!.approvalDate!) : 'No'}',
                              style: kTextStyle.copyWith(color: kGreyTextColor),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
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
