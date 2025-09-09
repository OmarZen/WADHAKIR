import 'package:wadhakir/data/models/radio_station_model.dart';
import 'package:wadhakir/domain/repositories/radio_repository.dart';

class GetRadiosUseCase {
  final RadioRepository repository;
  GetRadiosUseCase(this.repository);

  Future<List<RadioStationModel>> call({String? language}) {
    return repository.fetchRadios(language: language);
  }
}
