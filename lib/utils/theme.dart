import 'package:flutter/material.dart';

// Custom light theme
final lightThemeData = ThemeData(
  // Primary color theme for light mode
  primaryColor: Colors.blue,
  brightness: Brightness.light,

  // Custom color scheme
  colorScheme: ColorScheme.light(
    primary: Colors.blue, // Main color
    secondary: Colors.amber, // Secondary color
    surface: Colors.white, // Surface color
    onSurface: Colors.black, // Text color on surfaces
  ),

  // Custom text styles (updated TextTheme)
  textTheme: TextTheme(
    titleLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black), // Replaced headline1 with titleLarge
    bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.black87), // Replaced bodyText1 with bodyLarge
    bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.black54), // Replaced bodyText2 with bodyMedium
    // Define other text styles as needed
  ),

  // Custom icon theme (only define it once)
  iconTheme: IconThemeData(
    color: Colors.black87, // Default icon color
    size: 24, // Default icon size
  ),

  // Custom properties for main and secondary grids
  scaffoldBackgroundColor: Colors.white, // Background color for the grid
  cardColor: Colors.white, // Card background color for widgets like grids

  // Other customizations if needed
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(), // Custom border for input fields
  ),
);

// Custom dark theme
final darkThemeData = ThemeData(
  // Primary color theme for dark mode
  primaryColor: Colors.blue,
  brightness: Brightness.dark,

  // Custom color scheme
  colorScheme: ColorScheme.dark(
    primary: Colors.blue, // Main color
    secondary: Colors.amber, // Secondary color
    surface: Colors.black, // Surface color
    onSurface: Colors.white, // Text color on surfaces
  ),

  // Custom text styles (updated TextTheme)
  textTheme: TextTheme(
    titleLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white), // Replaced headline1 with titleLarge
    bodyLarge: TextStyle(
        fontSize: 16, color: Colors.white), // Replaced bodyText1 with bodyLarge
    bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.white70), // Replaced bodyText2 with bodyMedium
  ),

  // Custom icon theme for dark mode (only define it once)
  iconTheme: IconThemeData(
    color: Colors.white70, // Icon color for dark mode
    size: 24, // Icon size
  ),

  // Custom background for dark mode
  scaffoldBackgroundColor: Colors.black,
  cardColor: Colors.grey[800],

  // Additional customizations as needed
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(),
  ),
);
