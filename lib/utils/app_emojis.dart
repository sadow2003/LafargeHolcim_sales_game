import 'package:flutter_emoji/flutter_emoji.dart';

final _parser = EmojiParser();

String _e(String name) => _parser.get(name).code;

class AppEmojis {
  AppEmojis._();

  static final trophy       = _e('trophy');
  static final gold         = _e('first_place_medal');
  static final silver       = _e('second_place_medal');
  static final bronze       = _e('third_place_medal');
  static final party        = _e('tada');
  static final medal        = _e('sports_medal');
  static final rocket       = _e('rocket');
  static final moneybag     = _e('moneybag');
  static final fire         = _e('fire');
  static final muscle       = _e('muscle');
  static final clap         = _e('clap');
  static final zap          = _e('zap');

  static final thumbsUp   = _e('+1');
  static final thumbsDown = _e('-1');
  static final heart      = _e('heart');
  static final smile      = _e('blush');
  static final cry        = _e('cry');

  static final medals = [gold, silver, bronze];
  static final reactions = [thumbsUp, thumbsDown, heart, fire, smile, cry];
}
