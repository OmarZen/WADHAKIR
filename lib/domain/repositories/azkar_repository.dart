import 'package:wadhakir/data/models/azkar_category.dart';
import 'package:wadhakir/data/models/azkar_item.dart';

abstract class AzkarRepository {
  Future<List<AzkarCategory>> getAllCategories();

  // Method to get a specific adhkar item by ID
  Future<AdhkarItem?> getAdhkarById(int id);
}
