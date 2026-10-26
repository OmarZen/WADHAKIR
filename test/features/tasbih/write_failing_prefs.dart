import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A store that reads [values] and refuses every write: a full disk, or a
/// platform channel that has gone away. Only what `TasbihRepository` calls is
/// implemented; anything else throws, so a new call shows up at once.
class WriteFailingPrefs extends Fake implements SharedPreferences {
  WriteFailingPrefs([Map<String, Object> values = const {}])
    : _values = {...values};

  final Map<String, Object> _values;
  int failedWrites = 0;

  @override
  Object? get(String key) => _values[key];

  @override
  Future<bool> setString(String key, String value) => _refuse(key);

  @override
  Future<bool> setInt(String key, int value) => _refuse(key);

  Future<bool> _refuse(String key) async {
    failedWrites++;
    throw StateError('write refused: $key');
  }
}
