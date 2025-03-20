import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/image_asset_constants.dart';
import '../../../core/routes/app_pages.dart';
import '../../../widgets/custom_button/general_button.dart';

class AccountVerificationSuccessful extends StatelessWidget {
  const AccountVerificationSuccessful({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = Get.width;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 25,
            ),
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(ImageAssetPath.logo, width: 200),
                  const SizedBox(
                    height: 8,
                  ),
                  const Text(
                    'Verification Successful',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Congratulations your account has been activated.Continue to start using the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  GeneralButton(
                      color: Theme.of(context).hintColor,
                      width: screenWidth,
                      text: 'Continue',
                      onTap: () => Get.offAllNamed(Routes.initialScreen)
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
