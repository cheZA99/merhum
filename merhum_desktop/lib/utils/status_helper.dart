import 'package:flutter/material.dart';
import 'constants.dart';

class GraveSiteStatus {
  static const available = 'Available';
  static const occupied = 'Occupied';
  static const reserved = 'Reserved';

  static const _toDisplay = {
    'Available': 'Slobodno',
    'Occupied': 'Zauzeto',
    'Reserved': 'Rezervisano',
  };

  static const _toApi = {
    'Slobodno': 'Available',
    'Zauzeto': 'Occupied',
    'Rezervisano': 'Reserved',
  };

  static String display(String apiValue) => _toDisplay[apiValue] ?? apiValue;
  static String toApi(String displayValue) => _toApi[displayValue] ?? displayValue;

  static Color color(String apiValue) => switch (apiValue) {
        'Available' => AppColors.success,
        'Occupied' => AppColors.error,
        'Reserved' => Colors.orange,
        _ => AppColors.textLight,
      };

  static List<String> get apiValues => [available, occupied, reserved];
  static List<String> get displayValues => ['Slobodno', 'Zauzeto', 'Rezervisano'];
}
