import 'package:flutter/material.dart';

class OnboardingPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  const OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.gradient = const [Color(0xFFEBF5FF), Color(0xFFE6F0FF)],
  });
}
