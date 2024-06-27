import 'package:get/get.dart';
import 'package:staras_mobile/core/controllers/network_controller.dart';

class DependencyInjection {
  static void init() {
    Get.put<NetworkController>(NetworkController(), permanent: true);
  }
}
