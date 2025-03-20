import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class UtilityCard extends StatelessWidget {
  final String utilityName;
  final String utilityIcon;
  final Color color;
  final VoidCallback? onTap;
  const UtilityCard({super.key, required this.utilityName, required this.utilityIcon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    shape: BoxShape.circle
                ),
                child: Image.asset(
                  utilityIcon,
                  height: 50,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                )
              ),
              SizedBox(
                height: 8,
              ),

              Text(
                  utilityName.toUpperCase(),
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                  )
              ),
            ]
        ),
      ),
    );
  }
}
