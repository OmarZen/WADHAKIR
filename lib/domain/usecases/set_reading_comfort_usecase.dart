import 'package:wadhakir/core/reading/reading_comfort.dart';
import 'package:wadhakir/domain/repositories/app_settings_repository.dart';

/// Roadmap #24 — line spacing and font choice for reading surfaces.
class SetReadingComfortUseCase {
  final AppSettingsRepository _repository;

  SetReadingComfortUseCase(this._repository);

  Future<void> call(ReadingComfort comfort) async {
    await _repository.setReadingComfort(comfort);
  }
}
