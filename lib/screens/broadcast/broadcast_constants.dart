import 'package:flutter/material.dart';
import 'package:lafargeholcim_sales_game/utils/app_emojis.dart';

// emojies for reactions to broadcasts
final broadcastReactionEmojis = AppEmojis.reactions;

// For quick lookup of colors by type key
const broadcastTypeColors = {
  'milestone':   Color(0xFF8DC21F),
  'general':     Color(0xFFB0B0B0),
  'event':       Color(0xFF1565C0),
};

// For quick lookup of icons by type key
const broadcastTypeIcons = {
  'milestone':   Icons.stars_outlined,
  'general':     Icons.campaign_outlined,
  'event':       Icons.event_available_outlined,
};
