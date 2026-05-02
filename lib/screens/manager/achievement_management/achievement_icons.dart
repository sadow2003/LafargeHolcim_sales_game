import 'package:flutter/material.dart';

// Centralized mapping of achievement icon names to their corresponding IconData
const Map<String, IconData> achievementIconMap = {
  'trophy':  Icons.emoji_events,
  'star':    Icons.star,
  'medal':   Icons.military_tech,
  'fire':    Icons.local_fire_department,
  'rocket':  Icons.rocket_launch,
  'target':  Icons.gps_fixed,
  'diamond': Icons.diamond,
  'login':   Icons.login,
};

IconData iconFor(String? name) =>
    achievementIconMap[name] ?? Icons.military_tech;
