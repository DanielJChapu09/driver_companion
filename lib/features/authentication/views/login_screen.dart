import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_pages.dart';
import '../../../widgets/custom_button/general_button.dart';
import '../../../widgets/text_fields/custom_text_field.dart';
import '../helpers/helpers.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool hidePassword = true;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isFormValid = false;

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Log in',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              AnimatedOpacity(
                opacity: isFormValid ? 1.0 : 0.7,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    CustomTextField(
                      labelText: 'Email or username',
                      controller: usernameController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: passwordController,
                      labelText: 'Password',
                      obscureText: hidePassword,
                      suffixIconButton: IconButton(
                        onPressed: () => setState(() => hidePassword = !hidePassword),
                        icon: Icon(
                          hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Theme.of(context).hintColor,
                        ),
                        tooltip: hidePassword ? 'Show password' : 'Hide password',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              GeneralButton(
                  color: Theme.of(context).hintColor,
                  text: 'LOG IN',
                  onTap: () {
                    AuthHelpers.validateAndSubmitLoginForm(
                        email: usernameController.text.trim(),
                        password: passwordController.text.trim()
                    );
                  }
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () {

                },
                child: Text(
                  'Forgot Password?',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold
                  )
                ),
              ),

              const SizedBox(height: 32),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    const TextSpan(text: 'By signing in to '),
                    TextSpan(
                      text: 'CUT Nexus',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    const TextSpan(text: ' you agree to our '),
                    TextSpan(
                      text: 'Terms',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).hintColor,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          // Add terms navigation
                        },
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).hintColor,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          // Add privacy policy navigation
                        },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Get.toNamed(Routes.signUpScreen);
                },
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 16,
                    ),
                    children: [
                      const TextSpan(text: 'Don\'t have an account? '),
                      TextSpan(
                        text: 'SIGN UP',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}