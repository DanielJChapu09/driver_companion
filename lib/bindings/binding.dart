
import 'package:get/get.dart';
import 'package:mymaptest/config/confidential/apikeys.dart';
import 'package:mymaptest/features/community/controller/community_controller.dart';
import 'package:mymaptest/features/driver_behaviour/controller/driver_behaviour_controller.dart';
import 'package:mymaptest/features/main/controller/theme_controller.dart';

import '../core/utils/logs.dart';
import '../features/authentication/controller/auth_controller.dart';
import '../features/main/controller/botton_nav_controller.dart';
import '../features/navigation/controller/navigation_controller.dart';
import '../features/service_locator/controller/service_locator_controller.dart';
import '../widgets/snackbar/custom_snackbar.dart';

class InitialBinding extends Bindings {
  @override
  Future<void> dependencies() async {
    try {
      Get.put(
          AuthController(),
          permanent: true
      );

      Get.put(
          ThemeController(),
          permanent: true
      );

      Get.put(
          BottomNavController(),
          permanent: true
      );

      Get.put(
          DriverBehaviorController(),
          permanent: true
      );

      Get.lazyPut<CommunityController>(() => CommunityController(),);
      Get.lazyPut<NavigationController>(() => NavigationController(mapboxAccessToken: APIKeys.MAPBOXPUBLICTOKEN),);
      Get.lazyPut<ServiceLocatorController>(() => ServiceLocatorController(mapboxAccessToken: APIKeys.MAPBOXPUBLICTOKEN),);
      // Get.lazyPut<DriverBehaviorController>(() => DriverBehaviorController(),);


    } catch (error) {
      DevLogs.logError('Binding initialization error: $error');

      CustomSnackBar.showErrorSnackbar(message: 'Failed to initialize dependencies: $error');

      rethrow;
    }
  }
}
