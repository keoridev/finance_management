import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  const sampleRate = 44100;
  const durationSeconds = 2.4;
  final totalSamples = (sampleRate * durationSeconds).toInt();

  final audioData = Float64List(totalSamples);
  final rand = Random(12345);

  double whiteNoise() => (rand.nextDouble() * 2.0 - 1.0);

  // 1. Crisp paper bill counter sequence (from 0.15s to 1.95s)
  // ~28 bills counted in rapid succession (16-18 bills per second)
  const countStart = 0.18;
  const countEnd = 1.90;
  const billCount = 28;
  final billInterval = (countEnd - countStart) / billCount;

  for (int b = 0; b < billCount; b++) {
    // Slight human/mechanical jitter in interval
    final jitter = (rand.nextDouble() - 0.5) * 0.003;
    final billTime = countStart + b * billInterval + jitter;
    final startIndex = (billTime * sampleRate).toInt();

    // High quality tactile paper flick ("thwip / flit")
    final flickDuration = 0.028; // 28 ms
    final flickSamples = (flickDuration * sampleRate).toInt();

    final billPitch = 3200.0 + (rand.nextDouble() - 0.5) * 400.0;

    for (int j = 0; j < flickSamples && (startIndex + j) < totalSamples; j++) {
      final t = j / sampleRate;
      final decay = exp(-t * 140.0);
      final frictionDecay = exp(-t * 90.0);

      // 1. Sharp leading-edge tick (gate sensor)
      final tick = sin(2 * pi * billPitch * t) * decay * 0.45;
      // 2. Crisp paper flutter noise (trailing edge flicking off guide plate)
      final paperNoise = whiteNoise() * frictionDecay * 0.40;
      // 3. Resonant snap
      final snap = sin(2 * pi * (billPitch * 1.5) * t) * exp(-t * 220.0) * 0.25;

      audioData[startIndex + j] += (tick + paperNoise + snap);
    }
  }

  // 2. Subtle counting roller friction background (low pass whisper)
  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    if (t >= countStart && t <= countEnd) {
      final envelope = sin((t - countStart) / (countEnd - countStart) * pi);
      final rollerSound =
          (sin(2 * pi * 440.0 * t) * 0.04 + whiteNoise() * 0.03) * envelope;
      audioData[i] += rollerSound;
    }
  }

  // 3. Final cash delivery pocket drop / gate snap (2.0s - 2.25s)
  final dropTime = 2.02;
  final dIndex = (dropTime * sampleRate).toInt();
  for (
    int j = 0;
    j < (0.09 * sampleRate).toInt() && (dIndex + j) < totalSamples;
    j++
  ) {
    final t = j / sampleRate;
    final mechanicalClick =
        (sin(2 * pi * 1850.0 * t) * exp(-t * 120.0) * 0.5 +
        sin(2 * pi * 620.0 * t) * exp(-t * 70.0) * 0.4);
    audioData[dIndex + j] += mechanicalClick;
  }

  // Normalize
  double maxAmp = 0.0001;
  for (int i = 0; i < totalSamples; i++) {
    if (audioData[i].abs() > maxAmp) {
      maxAmp = audioData[i].abs();
    }
  }

  final pcmBytes = BytesBuilder();
  for (int i = 0; i < totalSamples; i++) {
    final normalized = (audioData[i] / maxAmp) * 0.90;
    final int sample16 = (normalized * 32767.0)
        .clamp(-32768.0, 32767.0)
        .toInt();
    pcmBytes.addByte(sample16 & 0xFF);
    pcmBytes.addByte((sample16 >> 8) & 0xFF);
  }

  final pcmData = pcmBytes.toBytes();
  final wavHeader = createWavHeader(
    pcmData.length,
    sampleRate: sampleRate,
    channels: 1,
    bitsPerSample: 16,
  );

  final outputFile = File('assets/sounds/atm_cash_count.wav');
  final totalBytes = BytesBuilder();
  totalBytes.add(wavHeader);
  totalBytes.add(pcmData);
  outputFile.writeAsBytesSync(totalBytes.toBytes());

  // ignore: avoid_print
  print(
    'Generated authentic banknote counter sound: ${outputFile.path} (${outputFile.lengthSync()} bytes)',
  );
}

Uint8List createWavHeader(
  int dataLength, {
  required int sampleRate,
  required int channels,
  required int bitsPerSample,
}) {
  final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
  final blockAlign = channels * (bitsPerSample ~/ 8);
  final buffer = ByteData(44);

  buffer.setUint8(0, 0x52);
  buffer.setUint8(1, 0x49);
  buffer.setUint8(2, 0x46);
  buffer.setUint8(3, 0x46); // 'RIFF'
  buffer.setUint32(4, 36 + dataLength, Endian.little);
  buffer.setUint8(8, 0x57);
  buffer.setUint8(9, 0x41);
  buffer.setUint8(10, 0x56);
  buffer.setUint8(11, 0x45); // 'WAVE'
  buffer.setUint8(12, 0x66);
  buffer.setUint8(13, 0x6D);
  buffer.setUint8(14, 0x74);
  buffer.setUint8(15, 0x20); // 'fmt '
  buffer.setUint32(16, 16, Endian.little);
  buffer.setUint16(20, 1, Endian.little);
  buffer.setUint16(22, channels, Endian.little);
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, byteRate, Endian.little);
  buffer.setUint16(32, blockAlign, Endian.little);
  buffer.setUint16(34, bitsPerSample, Endian.little);
  buffer.setUint8(36, 0x64);
  buffer.setUint8(37, 0x61);
  buffer.setUint8(38, 0x74);
  buffer.setUint8(39, 0x61); // 'data'
  buffer.setUint32(40, dataLength, Endian.little);

  return buffer.buffer.asUint8List();
}
