import 'package:flutter/material.dart';
import '../../../widgets/custom_button/general_button.dart';
import '../../../widgets/text_fields/custom_pin_input.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(
                'Enter Verification Code',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We have sent a verification code to your email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    CustomPinInput(
                      controller : pinController,
                      focusNode: focusNode
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {

                },
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 14,
                    ),
                    children: [
                      const TextSpan(text: 'Did\'t receive code? ', style: TextStyle(fontWeight: FontWeight.normal)),
                      TextSpan(
                        text: ' RESEND',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              GeneralButton(
                  color: Theme.of(context).hintColor,
                  text: 'VERIFY',
                  onTap: (){
                    if (formKey.currentState!.validate()) {
                      // Add verification success logic here
                    }
                  }
              ),
            ],
          ),
        ),
      ),
    );
  }
}