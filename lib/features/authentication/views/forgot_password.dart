import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/image_asset_constants.dart';
import '../../../core/routes/app_pages.dart';
import '../../../widgets/circular_loader/circular_loader.dart';
import '../../../widgets/custom_button/general_button.dart';
import '../../../widgets/text_fields/custom_text_field.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({
    super.key,
  });

  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(
              height: 50,
            ),
            CircleAvatar(
              radius: 120,
              backgroundColor: Colors.transparent,
              child: Image.asset(
                ImageAssetPath.logo,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(-5, -5),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(5, 5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Reset Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Enter your email and we will send you a password reset link',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  CustomTextField(
                    labelText: 'Email or username',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(
                    height: 20,
                  ),


                  GeneralButton(
                      color: Theme.of(context).hintColor,
                      text: 'RESET PASSWORD',
                    onTap: () async {
                      Get.dialog(
                          const CustomLoader(message: 'Resetting Password'));

                      await AuthServices.sendPasswordResetEmail(
                          email: emailController.text.trim())
                          .then((response) {
                        Get.offAllNamed(
                            Routes.resendVerificationEmailScreen,

                            arguments: [emailController.text.trim()]);
                      });
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
