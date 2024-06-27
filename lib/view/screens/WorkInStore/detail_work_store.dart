// ignore_for_file: depend_on_referenced_packages, library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:intl/intl.dart';
import 'package:staras_mobile/constants/constant.dart';
import 'package:staras_mobile/core/controllers/api_client.dart';
import 'package:staras_mobile/core/controllers/api_store.dart';
import 'package:staras_mobile/core/controllers/check_expired_token.dart';
import 'package:staras_mobile/model/store/details.store.model.dart';

class DetailsStore extends StatefulWidget {
  final int id;
  const DetailsStore({Key? key, required this.id}) : super(key: key);

  @override
  _DetailsStoreState createState() => _DetailsStoreState();
}

class _DetailsStoreState extends State<DetailsStore> {
  final StoreApiClient _apiClient = StoreApiClient();
  DetailsStoreModel? storeDetails;

  @override
  void initState() {
    super.initState();
    fetchDetailsStoreData();
  }

  Future<void> checkTokenExpiration() async {
    final String? accessToken = await readAccessToken();
    if (mounted) {
      await AuthManager.checkTokenExpiration(accessToken!, context);
      fetchDetailsStoreData();
    }
  }

  Future<void> fetchDetailsStoreData() async {
    final storeDetailsData = await _apiClient.fetchStoreDetails(widget.id);

    setState(() {
      storeDetails = storeDetailsData;
    });
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
          'Details Store',
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
              height: 1000,
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
                  Card(
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
                              Icons.store_rounded,
                              color: kMainColor,
                            ),
                            title: Text(
                              storeDetails?.storeName ?? "",
                              style: kTextStyle.copyWith(
                                fontSize: 13.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Manager: ${storeDetails?.storeManager ?? ""}',
                              style: kTextStyle.copyWith(
                                  color: kGreyTextColor, fontSize: 13),
                            ),
                            trailing: Text(
                              storeDetails?.active == true
                                  ? 'Active'
                                  : 'Not Active',
                              style: kTextStyle.copyWith(
                                color: storeDetails?.active == true
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Divider(
                            color: kBorderColorTextField.withOpacity(0.2),
                            thickness: 1,
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Open time     : ${storeDetails?.openTime ?? " "}',
                            style: kTextStyle.copyWith(color: kGreyTextColor),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Close time    : ${storeDetails?.closeTime ?? " "}',
                            style: kTextStyle.copyWith(color: kGreyTextColor),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Assigned       : ${storeDetails?.createDate != null ? DateFormat('dd, MMMM yyyy').format(storeDetails!.createDate!) : ''}',
                            style: kTextStyle.copyWith(color: kGreyTextColor),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Address         : ${storeDetails?.address ?? " "}',
                            maxLines: 5,
                            style: kTextStyle.copyWith(color: kGreyTextColor),
                          ),
                          const SizedBox(
                            height: 2.0,
                          ),
                        ],
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
