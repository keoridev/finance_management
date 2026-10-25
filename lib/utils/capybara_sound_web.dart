import 'dart:js_interop';

@JS('eval')
external JSAny? _eval(String code);

class CapybaraSoundImpl {
  static void playWaterDrop() {
    try {
      _eval('''
        (function() {
          try {
            var AudioContext = window.AudioContext || window.webkitAudioContext;
            if (!AudioContext) return;
            var ctx = window._capyAudioCtx = window._capyAudioCtx || new AudioContext();
            if (ctx.state === 'suspended') { ctx.resume(); }
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = 'sine';
            osc.frequency.setValueAtTime(600, ctx.currentTime);
            osc.frequency.exponentialRampToValueAtTime(1400, ctx.currentTime + 0.12);
            gain.gain.setValueAtTime(0.28, ctx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.005, ctx.currentTime + 0.16);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start();
            osc.stop(ctx.currentTime + 0.16);
          } catch(e) {}
        })();
      ''');
    } catch (_) {}
  }

  static void playZenChime() {
    try {
      _eval('''
        (function() {
          try {
            var AudioContext = window.AudioContext || window.webkitAudioContext;
            if (!AudioContext) return;
            var ctx = window._capyAudioCtx = window._capyAudioCtx || new AudioContext();
            if (ctx.state === 'suspended') { ctx.resume(); }
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = 'sine';
            osc.frequency.setValueAtTime(528, ctx.currentTime); // 528Hz Solfeggio frequency
            gain.gain.setValueAtTime(0.3, ctx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 1.2);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start();
            osc.stop(ctx.currentTime + 1.2);
          } catch(e) {}
        })();
      ''');
    } catch (_) {}
  }

  static void playOrangePop() {
    try {
      _eval('''
        (function() {
          try {
            var AudioContext = window.AudioContext || window.webkitAudioContext;
            if (!AudioContext) return;
            var ctx = window._capyAudioCtx = window._capyAudioCtx || new AudioContext();
            if (ctx.state === 'suspended') { ctx.resume(); }
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = 'triangle';
            osc.frequency.setValueAtTime(320, ctx.currentTime);
            osc.frequency.exponentialRampToValueAtTime(780, ctx.currentTime + 0.08);
            gain.gain.setValueAtTime(0.25, ctx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.1);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start();
            osc.stop(ctx.currentTime + 0.1);
          } catch(e) {}
        })();
      ''');
    } catch (_) {}
  }
}
