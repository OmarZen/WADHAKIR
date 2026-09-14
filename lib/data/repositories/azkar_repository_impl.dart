import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:wadhakir/data/models/azkar_category.dart';
import 'package:wadhakir/data/models/azkar_item.dart';

import '../../domain/repositories/azkar_repository.dart';

class AzkarRepositoryImpl extends AzkarRepository {
  @override
  Future<List<AzkarCategory>> getAllCategories() async {
    try {
      // Load the Adhkar JSON file
      final String response = await rootBundle.loadString(
        'assets/json_data/adhkar.json',
      );
      final List<dynamic> data = json.decode(response);

      List<AzkarCategory> categories = [];

      // Parse each category from the JSON data
      for (var categoryData in data) {
        if (categoryData is Map<String, dynamic>) {
          final category = AzkarCategory.fromAdhkarJson(categoryData);
          categories.add(category);
        }
      }

      return categories;
    } catch (e) {
      log('Error loading Adhkar data: $e');
      rethrow; // Rethrow to allow error handling in the UI
    }
  }

  // Method to get a specific adhkar item by ID
  @override
  Future<AdhkarItem?> getAdhkarById(int id) async {
    try {
      final String response = await rootBundle.loadString(
        'assets/json_data/adhkar.json',
      );
      final List<dynamic> data = json.decode(response);

      // Find the specific adhkar item
      for (var category in data) {
        if (category['id'] == id) {
          return AdhkarItem.fromJson(category);
        }

        // Check in category arrays
        if (category['array'] != null) {
          for (var item in category['array']) {
            if (item['id'] == id) {
              return AdhkarItem.fromJson(item);
            }
          }
        }
      }

      return null;
    } catch (e) {
      log('Error getting Adhkar by ID: $e');
      return null;
    }
  }
}
