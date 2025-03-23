
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/image_asset_constants.dart';
import '../../../widgets/custom_button/general_button.dart';
import '../../../widgets/snackbar/custom_snackbar.dart';
import '../helpers/helpers.dart';

class EmailVerificationScreen extends StatefulWidget {
  final User user;

  const EmailVerificationScreen({super.key, required this.user});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    AuthHelpers.setTimerForAutoRedirect();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = Get.width;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: (){
                      AuthHelpers.signOut();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration:  BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).hintColor
                      ),
                      child: const Icon(
                        Icons.close,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
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
                      'Verify you email address',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\n${widget.user.email}\n',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Congratulations your account awaits. Verify your email to start and get going.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    GeneralButton(
                        color: Theme.of(context).hintColor,
                        width: screenWidth,
                        text: 'Continue',
                        onTap: () => AuthHelpers.checkEmailVerification(
                            currentUser: _currentUser
                        )
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    GestureDetector(
                      onTap: () async {
                        await FirebaseAuth.instance.currentUser!.sendEmailVerification();

                        CustomSnackBar.showSuccessSnackbar(message: 'Verification Email Sent');

                      },
                      child: RichText(
                        text: TextSpan(
                            style: TextStyle(
                                fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                  text: "Didn't receive the email? "),
                              TextSpan(
                                  text: " Resend",
                                  style: TextStyle(
                                      color: Theme.of(context).hintColor,
                                      fontWeight: FontWeight.bold))
                            ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
