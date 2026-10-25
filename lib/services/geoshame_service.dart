import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';
import '../state/notification_controller.dart';

class DangerZone {
  final String id;
  final String name;
  final String address;
  final String riskCategory;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String toxicWarning;

  const DangerZone({
    required this.id,
    required this.name,
    required this.address,
    required this.riskCategory,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 200.0,
    required this.toxicWarning,
  });
}

class GeoshameService {
  static const String _prefKey = 'arc_geoshame_enabled';
  static bool _isEnabled = true;
  static DateTime? _lastTriggerTime;

  static const List<DangerZone> bishkekDangerZones = [
    DangerZone(
      id: 'dz_faiza',
      name: 'Кафе «Фаиза»',
      address: 'ул. Медерова / ул. Жибек Жолу',
      riskCategory: 'Опасный лагман и манты',
      latitude: 42.8519,
      longitude: 74.6148,
      radiusMeters: 250.0,
      toxicWarning:
          '«Я всё вижу. Убери кошелек, мы копим на Mac M3! Либо покупаешь только воду!»',
    ),
    DangerZone(
      id: 'dz_dordoi_plaza',
      name: 'ТРЦ «Дордой Плаза»',
      address: 'ул. Ибраимова, 115',
      riskCategory: 'Спонтанный шоппинг и бутики',
      latitude: 42.8752,
      longitude: 74.6163,
      radiusMeters: 300.0,
      toxicWarning:
          '«Ты зависаешь в Дордой Плазе! Положи банковскую карту в самый дальний карман и немедленно покинь периметр!»',
    ),
    DangerZone(
      id: 'dz_asia_mall',
      name: 'ТРЦ «Asia Mall»',
      address: 'пр. Чынгыза Айтматова, 3',
      riskCategory: 'Фудкорт и кинотеатр',
      latitude: 42.8554,
      longitude: 74.5869,
      radiusMeters: 300.0,
      toxicWarning:
          '«Запах фудкорта в Asia Mall не должен сломать твой стрик Winter Arc. Вспомни баланс счета!»',
    ),
    DangerZone(
      id: 'dz_bishkek_park',
      name: 'ТРЦ «Bishkek Park»',
      address: 'ул. Киевская, 148',
      riskCategory: 'Кофейни и развлечения',
      latitude: 42.8750,
      longitude: 74.5910,
      radiusMeters: 250.0,
      toxicWarning:
          '«Бишкек Парк затягивает. Никаких покупок дороже 0 сом, держи железную дисциплину!»',
    ),
    DangerZone(
      id: 'dz_navat',
      name: 'Чайхана «Navat»',
      address: 'ул. Токомбаева / ул. Киевская',
      riskCategory: 'Праздничный пир',
      latitude: 42.8270,
      longitude: 74.6180,
      radiusMeters: 200.0,
      toxicWarning:
          '«Чайхана Navat зафиксирована радаром. Пей зелёный чай без сахара и десертов — мы копим на мечту!»',
    ),
  ];

  static bool get isEnabled => _isEnabled;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_prefKey) ?? true;
    } catch (_) {}
  }

  static Future<void> setEnabled(bool value) async {
    _isEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {}
  }

  /// Calculates geodesic distance using Haversine formula (meters)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // in meters
    final double dLat = (lat2 - lat1) * (pi / 180.0);
    final double dLon = (lon2 - lon1) * (pi / 180.0);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Simulates entering or checks proximity to a danger zone
  static DangerZone? checkProximity(double userLat, double userLon) {
    if (!_isEnabled) return null;

    for (final zone in bishkekDangerZones) {
      final dist = calculateDistance(
        userLat,
        userLon,
        zone.latitude,
        zone.longitude,
      );
      if (dist <= zone.radiusMeters) {
        return zone;
      }
    }
    return null;
  }

  /// Triggers sensory Geoshame alert: haptic vibration + in-app banner / push
  static void triggerShameAlert(
    BuildContext context,
    DangerZone zone, {
    NotificationController? notificationController,
  }) {
    final now = DateTime.now();
    if (_lastTriggerTime != null &&
        now.difference(_lastTriggerTime!).inSeconds < 10) {
      // Throttle repetitive triggers
      return;
    }
    _lastTriggerTime = now;

    // Dual strong haptic pulse
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 180), () {
      HapticFeedback.heavyImpact();
    });

    if (notificationController != null) {
      notificationController.showNotification(
        AppNotification(
          id: 'geoshame_${now.millisecondsSinceEpoch}',
          type: NotificationType.hourlyExpense,
          title: 'ГЕО-ШЕЙМИНГ: ${zone.name}',
          body: zone.toxicWarning,
          actionLabel: 'Понял, ухожу',
          onAction: () {
            notificationController.dismissActiveNotification();
          },
        ),
      );
    }
  }
}
