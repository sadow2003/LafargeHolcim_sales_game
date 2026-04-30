import 'package:flutter/material.dart';

// emojies for reactions to broadcasts
const broadcastReactionEmojis = ['🔥', '💪', '🏆', '👏', '⚡'];

// Centralized constants for broadcast types, hints, colors, and icons
const broadcastTypes = [
  {'key': 'achievement', 'label': 'Achievement', 'icon': Icons.emoji_events_outlined, 'color': Color(0xFFFFD700)},
  {'key': 'goal',        'label': 'Goal',        'icon': Icons.flag_outlined,          'color': Color(0xFF00AEEF)},
  {'key': 'milestone',   'label': 'Milestone',   'icon': Icons.stars_outlined,         'color': Color(0xFF8DC21F)},
  {'key': 'general',     'label': 'General',     'icon': Icons.campaign_outlined,      'color': Color(0xFFB0B0B0)},
];

// For quick lookup of labels by type key
const broadcastHints = {
  'achievement': 'e.g. Just closed my biggest deal ever! 🎉',
  'goal':        'e.g. My goal this month: reach the top 3!',
  'milestone':   'e.g. Just hit 500 points — and counting! 💪',
  'general':     'Share something with your team...',
};

// For quick lookup of colors by type key
const broadcastTypeColors = {
  'achievement': Color(0xFFFFD700),
  'goal':        Color(0xFF00AEEF),
  'milestone':   Color(0xFF8DC21F),
  'general':     Color(0xFFB0B0B0),
};

// For quick lookup of icons by type key
const broadcastTypeIcons = {
  'achievement': Icons.emoji_events_outlined,
  'goal':        Icons.flag_outlined,
  'milestone':   Icons.stars_outlined,
  'general':     Icons.campaign_outlined,
};
