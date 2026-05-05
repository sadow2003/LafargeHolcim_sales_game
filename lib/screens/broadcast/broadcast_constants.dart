import 'package:flutter/material.dart';

// emojies for reactions to broadcasts
const broadcastReactionEmojis = ['🔥', '💪', '🏆', '👏', '⚡'];

// Types users can manually select when posting
const broadcastTypes = [
  {'key': 'general',   'label': 'General',   'icon': Icons.campaign_outlined, 'color': Color(0xFFB0B0B0)},
];

// For quick lookup of labels by type key
const broadcastHints = {
  'general':     'Share something with your team...',
};

// For quick lookup of colors by type key
const broadcastTypeColors = {
  'milestone':   Color(0xFF8DC21F),
  'general':     Color(0xFFB0B0B0),
};

// For quick lookup of icons by type key
const broadcastTypeIcons = {
  'milestone':   Icons.stars_outlined,
  'general':     Icons.campaign_outlined,
};
