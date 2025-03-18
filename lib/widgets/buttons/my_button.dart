import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String iconImagePath;
  final String buttonText;

  const MyButton({
    super.key, required this.iconImagePath, required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 50,
          // Remove or reduce padding
          padding: EdgeInsets.zero,
          decoration: const BoxDecoration(
            color: Colors.grey,
          ),
          // Clip the image to the container's rounded corners
          child: ClipRRect(
            child: Image.asset(
              iconImagePath,
              fit: BoxFit.cover, // Adjust to BoxFit.cover or BoxFit.contain as needed
            ),
          ),
        ),
        const SizedBox(height: 12,),
        Text(
          buttonText,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey,),
        )
      ],
    );
  }
}
