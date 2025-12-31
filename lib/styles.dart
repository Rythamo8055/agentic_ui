import 'package:flutter/material.dart';

class AppColors {
  // Use exact hex codes provided by user
  static const Color frozenWater = Color(0xFFC9E4DE);
  static const Color softBlush = Color(0xFFF8EDEB);
  static const Color desertSand = Color(0xFFF7D9C4); // Added '4' to complete hex
  static const Color parchment = Color(0xFFEDEDE9);
  static const Color lavender = Color(0xFFDFE7FD);
  static const Color almondPetal = Color(0xFFDDC9BD);
  static const Color aliceBlue = Color(0xFFE1EFFF);   // Adjusted 'G' to 'F'
  static const Color delicateRose = Color(0xFFFFE4EF);
  static const Color powderBlue = Color(0xFFBCD5F1);
}

class AppStyle {
  static const double kBorderRadius = 24.0;
  static const double kCardPadding = 24.0;
  
  static final BorderRadius roundedBorder = BorderRadius.circular(kBorderRadius);
  
  static final cardShape = RoundedRectangleBorder(
    borderRadius: roundedBorder,
  );
}
