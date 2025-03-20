import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String iconImagePath;
  final String buttonText;
  final VoidCallback? onPressed;  // Add this line

  const MyButton({
    super.key,
    required this.iconImagePath,
    required this.buttonText,
    this.onPressed,  // Add this line
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            height: 60,
            // Remove or reduce padding
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            // Clip the image to the container's rounded corners
            child: ClipRRect(
              child: Image.asset(
                iconImagePath,
                fit: BoxFit.cover, // Adjust to BoxFit.cover or BoxFit.contain as needed
              ),
            ),
          ),
          const SizedBox(height: 10,),
          Text(
            buttonText,
            style: const TextStyle(fontSize: 10,),
          )
        ],
      ),
    );
  }
}

