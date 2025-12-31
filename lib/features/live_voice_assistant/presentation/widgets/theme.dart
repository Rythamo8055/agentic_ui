import 'package:flutter/material.dart';

ThemeData themeData = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color.fromARGB(255, 18, 69, 2),
    brightness: Brightness.dark,
    dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
  ).copyWith(surface: Color.fromARGB(255, 7, 41, 21)),
);
