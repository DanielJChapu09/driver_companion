import 'package:get/get.dart';

class BottomNavController extends GetxController {
  var currentIndex = 0.obs;

  void navigateTo(int index) {
    if (currentIndex.value != index) {
      currentIndex.value = index;
    }
  }

  void navigateToHome() => navigateTo(0);
  void navigateToMeters() => navigateTo(1);
  void navigateToSettings() => navigateTo(2);
}
