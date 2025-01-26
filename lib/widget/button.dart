import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final double fontSize;
  final Color textColor;
  final double width;
  final double height;
  final double borderRadius;

  // Constructor with default values for customization
  const CustomButton({
    required this.text,
    required this.onPressed,
    this.backgroundColor = Colors.blue, // Set to #00AB66
    this.fontSize = 16,                  // Default font size
    this.textColor = Colors.white,       // Default text color
    this.width = double.infinity,        // Default width
    this.height = 50,                    // Default height
    this.borderRadius = 5,              // Default border radius
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            color: textColor,
          ),
        ),
      ),
    );
  }
}