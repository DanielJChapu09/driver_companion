import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class CustomPinInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  const CustomPinInput({super.key, required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return Pinput(
      controller: controller,
      focusNode: focusNode,
      defaultPinTheme: PinTheme(
        width: 56,
        height: 56,
        textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).disabledColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      focusedPinTheme: PinTheme(
        width: 56,
        height: 56,
        textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).hintColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      submittedPinTheme: PinTheme(
        width: 56,
        height: 56,
        textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(color: Theme.of(context).disabledColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        return value == '2222' ? null : 'Pin is incorrect';
      },
      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
      showCursor: true,
      onCompleted: (pin) {
        print(pin);
        // Add your verification logic here
      },
    );
  }
}
