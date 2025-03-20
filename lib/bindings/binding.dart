
import 'package:get/get.dart';
import 'package:mymaptest/features/main/controller/theme_controller.dart';

import '../core/utils/logs.dart';
import '../features/authentication/controller/auth_controller.dart';
import '../features/main/controller/botton_nav_controller.dart';
import '../widgets/snackbar/custom_snackbar.dart';

class InitialBinding extends Bindings {
  @override
  Future<void> dependencies() async {
    try {
      Get.put(
          ThemeController(),
          permanent: true
      );

      Get.put(
          BottomNavController(),
          permanent: true
      );

      Get.lazyPut<AuthController>(() => AuthController(),);

    } catch (error) {
      DevLogs.logError('Binding initialization error: $error');

      CustomSnackBar.showErrorSnackbar(message: 'Failed to initialize dependencies: $error');

      rethrow;
    }
  }
}
