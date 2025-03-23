import 'package:flutter/material.dart';

class ServiceCard extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback? onPressed;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.title,
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
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(

            ),
            child: ClipRRect(
              child: Image.asset(
                icon,
                color: Theme.of(context).textTheme.bodyLarge!.color,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 10,),
          Text(
            title,
            style: const TextStyle(fontSize: 10,),
          )
        ],
      ),
    );
  }
}

