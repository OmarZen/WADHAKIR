// Generates android/app/src/main/res/raw/tasbih_click.wav.
//
//   dart run tool/gen_tasbih_click.dart
//
// The tasbih's click is synthesised here rather than downloaded, so the app
// owns it outright — no licence to track, and anyone can see exactly what it
// is and regenerate it byte for byte.
//
// The sound: a short wooden "tock", like one bead knocking another.
//  * a 2 ms burst of noise for the contact,
//  * three damped sines for the body (a low knock and two brighter partials),
//  * 50 ms in all, mono, 22.05 kHz, 16-bit PCM — about 2 KB.
//
// Played through SoundPool by TasbihFeedbackBridge.kt.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int _sampleRate = 22050;
const double _seconds = 0.050;

/// Peak level, a little under full scale, so the click is crisp without
/// clipping on phones that boost the system stream.
const double _peak = 0.7;

/// (frequency Hz, amplitude, decay time constant s)
const List<(double, double, double)> _partials = [
  (720, 0.30, 0.010),
  (1850, 0.60, 0.006),
  (3300, 0.35, 0.0035),
];

void main() {
  final n = (_sampleRate * _seconds).round();
  final samples = Float64List(n);

  // A fixed-seed generator, so the output is identical on every run.
  var seed = 0x2545F491;
  double noise() {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed / 0x3fffffff - 1;
  }

  final contact = (_sampleRate * 0.002).round();
  for (var i = 0; i < n; i++) {
    final t = i / _sampleRate;
    var v = 0.0;
    for (final (f, a, tau) in _partials) {
      v += a * math.exp(-t / tau) * math.sin(2 * math.pi * f * t);
    }
    if (i < contact) {
      v += 0.5 * noise() * (1 - i / contact);
    }
    // A 0.3 ms ramp in, so the very first sample does not pop, and the last
    // 5 ms faded to silence, so the tail ends on zero.
    final attack = math.min(1.0, t / 0.0003);
    final release = math.min(1.0, (_seconds - t) / 0.005);
    samples[i] = v * attack * release;
  }

  var max = 0.0;
  for (final s in samples) {
    max = math.max(max, s.abs());
  }
  final gain = max == 0 ? 0 : _peak / max;

  final pcm = ByteData(n * 2);
  for (var i = 0; i < n; i++) {
    final s = (samples[i] * gain * 32767).round().clamp(-32768, 32767);
    pcm.setInt16(i * 2, s, Endian.little);
  }

  final header = ByteData(44);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      header.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  const channels = 1;
  const bits = 16;
  final dataBytes = n * 2;
  ascii(0, 'RIFF');
  header.setUint32(4, 36 + dataBytes, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  header.setUint32(16, 16, Endian.little); // PCM fmt chunk size
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, channels, Endian.little);
  header.setUint32(24, _sampleRate, Endian.little);
  header.setUint32(28, _sampleRate * channels * bits ~/ 8, Endian.little);
  header.setUint16(32, channels * bits ~/ 8, Endian.little);
  header.setUint16(34, bits, Endian.little);
  ascii(36, 'data');
  header.setUint32(40, dataBytes, Endian.little);

  const target = 'android/app/src/main/res/raw/tasbih_click.wav';
  final bytes = BytesBuilder()
    ..add(header.buffer.asUint8List())
    ..add(pcm.buffer.asUint8List());
  File(target)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes.takeBytes());
  stdout.writeln('wrote $target (${44 + dataBytes} bytes)');
}
