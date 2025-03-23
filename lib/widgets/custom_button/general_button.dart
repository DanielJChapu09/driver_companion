import 'package:flutter/material.dart';
import '../../core/utils/dimensions.dart';

class GeneralButton extends StatefulWidget {
  final Color? color;
  final Color? shadowColor;
  final double? width;
  final double? height;
  final double? borderRadius;
  final BoxBorder? boxBorder;
  final String text;
  final Color? textColor;
  final void Function()? onTap;

  const GeneralButton({
    super.key,
    this.color,
    this.shadowColor,
    this.width,
    this.height,
    this.borderRadius,
    this.boxBorder,
    required this.text,
    this.onTap,
    this.textColor,
  });

  @override
  State<GeneralButton> createState() => _GeneralButtonState();
}

class _GeneralButtonState extends State<GeneralButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _shadowAnimation = Tween<double>(begin: 3.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width ?? Dimensions.screenWidth,
              height: widget.height ?? 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.color ?? Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 14),
                border: widget.boxBorder,
                boxShadow: [
                  BoxShadow(
                    color: widget.color ?? Theme.of(context).primaryColor,
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: Offset(0, _shadowAnimation.value),
                  ),
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white12
                        : Colors.black12,
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: Offset(0, _shadowAnimation.value),
                  ),

                  BoxShadow(
                    color: widget.color ?? Theme.of(context).primaryColor,
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: const Offset(0, 0.3),
                  ),

                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white12
                        : Colors.black12,
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: const Offset(0, 0.3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.textColor ?? Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}