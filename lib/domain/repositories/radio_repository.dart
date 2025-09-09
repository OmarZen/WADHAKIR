import 'package:wadhakir/data/models/radio_station_model.dart';

abstract class RadioRepository {
  Future<List<RadioStationModel>> fetchRadios({String? language});
}
