/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/11/27 08:33
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'package:flutter/material.dart';

class ThemedLogo extends StatelessWidget {
  final double? width;
  final double? height;

  const ThemedLogo({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark ? 'assets/images/logo_dark_theme.png' : 'assets/images/logo_light_theme.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback if assets not loaded correctly (e.g. testing)
        return Icon(
          Icons.play_circle_filled, 
          size: width ?? 48, 
          color: isDark ? Colors.white : Colors.black
        );
      },
    );
  }
}
