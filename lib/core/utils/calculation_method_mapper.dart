import 'package:adhan_dart/adhan_dart.dart';

/// Maps calculation method names to adhan_dart CalculationParameters
/// This helper ensures compatibility between stored method names and the new package
class CalculationMethodMapper {
  /// Available calculation methods with their display names
  static const Map<String, String> methodNames = {
    'muslim_world_league': 'Muslim World League',
    'egyptian': 'Egyptian General Authority',
    'karachi': 'University of Islamic Sciences, Karachi',
    'umm_al_qura': 'Umm al-Qura University, Makkah',
    'dubai': 'Dubai',
    'qatar': 'Qatar',
    'kuwait': 'Kuwait',
    'singapore': 'Singapore',
    'north_america': 'Islamic Society of North America (ISNA)',
    'moonsighting_committee': 'Moonsighting Committee Worldwide',
    'turkiye': 'Turkiye',
    'tehran': 'Institute of Geophysics, University of Tehran',
  };

  /// Get CalculationParameters from method name string
  ///
  /// [methodName] - The stored method name (e.g., 'muslim_world_league')
  ///
  /// Returns the corresponding CalculationParameters object
  static CalculationParameters getParameters(String methodName) {
    switch (methodName.toLowerCase()) {
      case 'muslim_world_league':
        return CalculationMethodParameters.muslimWorldLeague();
      case 'egyptian':
        return CalculationMethodParameters.egyptian();
      case 'karachi':
        return CalculationMethodParameters.karachi();
      case 'umm_al_qura':
        return CalculationMethodParameters.ummAlQura();
      case 'dubai':
        return CalculationMethodParameters.dubai();
      case 'qatar':
        return CalculationMethodParameters.qatar();
      case 'kuwait':
        return CalculationMethodParameters.kuwait();
      case 'singapore':
        return CalculationMethodParameters.singapore();
      case 'north_america':
        return CalculationMethodParameters.northAmerica();
      case 'moonsighting_committee':
        return CalculationMethodParameters.moonsightingCommittee();
      case 'turkiye':
        return CalculationMethodParameters.turkiye();
      case 'tehran':
        return CalculationMethodParameters.tehran();
      default:
        // Default to Muslim World League if unknown method
        return CalculationMethodParameters.muslimWorldLeague();
    }
  }

  /// Get method name string from CalculationParameters
  ///
  /// [params] - The CalculationParameters object
  ///
  /// Returns the method name as a string for storage
  static String getMethodName(CalculationParameters params) {
    // Compare method property to determine which calculation method
    final method = params.method;

    if (method == CalculationMethod.muslimWorldLeague) {
      return 'muslim_world_league';
    }
    if (method == CalculationMethod.egyptian) return 'egyptian';
    if (method == CalculationMethod.karachi) return 'karachi';
    if (method == CalculationMethod.ummAlQura) return 'umm_al_qura';
    if (method == CalculationMethod.dubai) return 'dubai';
    if (method == CalculationMethod.qatar) return 'qatar';
    if (method == CalculationMethod.kuwait) return 'kuwait';
    if (method == CalculationMethod.singapore) return 'singapore';
    if (method == CalculationMethod.northAmerica) return 'north_america';
    if (method == CalculationMethod.moonsightingCommittee) {
      return 'moonsighting_committee';
    }
    if (method == CalculationMethod.turkiye) return 'turkiye';
    if (method == CalculationMethod.tehran) return 'tehran';

    // Default fallback
    return 'muslim_world_league';
  }

  /// Return a sensible default calculation method for an ISO 3166-1 alpha-2
  /// country code. Falls back to Muslim World League when the country isn't
  /// recognised or null.
  static String defaultMethodForCountry(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) {
      return 'muslim_world_league';
    }
    switch (countryCode.toUpperCase()) {
      case 'EG':
      case 'SD': // Sudan historically follows the Egyptian standard
      case 'SY':
      case 'IQ':
      case 'LB':
      case 'JO':
      case 'PS':
        return 'egyptian';
      case 'SA':
        return 'umm_al_qura';
      case 'AE':
        return 'dubai';
      case 'QA':
        return 'qatar';
      case 'KW':
        return 'kuwait';
      case 'BH':
      case 'OM':
      case 'YE':
        return 'umm_al_qura';
      case 'DZ':
      case 'MA':
      case 'TN':
      case 'LY':
        return 'muslim_world_league';
      case 'TR':
        return 'turkiye';
      case 'PK':
      case 'IN':
      case 'BD':
      case 'AF':
        return 'karachi';
      case 'IR':
        return 'tehran';
      case 'SG':
      case 'MY':
      case 'ID':
      case 'BN':
        return 'singapore';
      case 'US':
      case 'CA':
      case 'MX':
        return 'north_america';
      default:
        return 'muslim_world_league';
    }
  }

  /// Get Arabic display name for method
  ///
  /// [methodName] - The method name string
  ///
  /// Returns the Arabic translation of the method name
  static String getArabicName(String methodName) {
    switch (methodName.toLowerCase()) {
      case 'muslim_world_league':
        return 'رابطة العالم الإسلامي';
      case 'egyptian':
        return 'الهيئة العامة المصرية للمساحة';
      case 'karachi':
        return 'جامعة العلوم الإسلامية، كراتشي';
      case 'umm_al_qura':
        return 'جامعة أم القرى، مكة المكرمة';
      case 'dubai':
        return 'دبي';
      case 'qatar':
        return 'قطر';
      case 'kuwait':
        return 'الكويت';
      case 'singapore':
        return 'سنغافورة';
      case 'north_america':
        return 'الجمعية الإسلامية لأمريكا الشمالية';
      case 'moonsighting_committee':
        return 'لجنة رؤية الهلال العالمية';
      case 'turkiye':
        return 'تركيا';
      case 'tehran':
        return 'معهد الجيوفيزياء، جامعة طهران';
      default:
        return 'رابطة العالم الإسلامي';
    }
  }
}
