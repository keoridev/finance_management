import 'capybara_sound_stub.dart'
    if (dart.library.js_interop) 'capybara_sound_web.dart';

abstract class CapybaraSound {
  static void playWaterDrop() => CapybaraSoundImpl.playWaterDrop();
  static void playZenChime() => CapybaraSoundImpl.playZenChime();
  static void playOrangePop() => CapybaraSoundImpl.playOrangePop();
}
