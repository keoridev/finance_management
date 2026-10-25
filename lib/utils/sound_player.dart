import 'package:audioplayers/audioplayers.dart';

class SoundPlayer {
  static AudioPlayer? _player;

  static Future<void> playAtmSound() async {
    try {
      _player ??= AudioPlayer();
      await _player!.stop();
      await _player!.play(AssetSource('sounds/atm_cash_count.wav'), volume: 0.85);
    } catch (_) {}
  }
}
