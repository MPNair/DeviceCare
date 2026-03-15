import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { system, light, dark }

enum Currency { usd, eur, gbp, inr, jpy }

class CustomReminder {
  final String deviceName;
  final DateTime date;
  final bool repeat;
  CustomReminder(this.deviceName, this.date, {this.repeat = false});

  Map<String, dynamic> toJson() {
    return {
      'deviceName': deviceName,
      'date': date.toIso8601String(),
      'repeat': repeat,
    };
  }

  factory CustomReminder.fromJson(Map<String, dynamic> json) {
    return CustomReminder(
      (json['deviceName'] ?? '').toString(),
      DateTime.parse((json['date'] ?? '').toString()),
      repeat: json['repeat'] == true,
    );
  }
}

class SettingsProvider with ChangeNotifier {
  static const String _themeKey = 'settings.theme';
  static const String _currencyKey = 'settings.currency';
  static const String _notificationsEnabledKey =
      'settings.notificationsEnabled';
  static const String _isLoggedInKey = 'settings.isLoggedIn';
  static const String _userNameKey = 'settings.userName';
  static const String _userEmailKey = 'settings.userEmail';
  static const String _authTokenKey = 'settings.authToken';
  static const String _customRemindersKey = 'settings.customReminders';

  AppTheme _theme = AppTheme.dark;
  Currency _currency = Currency.inr;
  bool _notificationsEnabled = true;
  bool _isLoggedIn = false;
  String _userName = 'Guest User';
  String _userEmail = 'guest@devicecare.local';
  String? _authToken;

  final List<CustomReminder> customReminders = [];

  AppTheme get theme => _theme;
  Currency get currency => _currency;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String? get authToken => _authToken;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    final storedTheme = prefs.getString(_themeKey);
    if (storedTheme != null) {
      _theme = AppTheme.values.firstWhere(
        (e) => e.name == storedTheme,
        orElse: () => AppTheme.dark,
      );
    }

    final storedCurrency = prefs.getString(_currencyKey);
    if (storedCurrency != null) {
      _currency = Currency.values.firstWhere(
        (e) => e.name == storedCurrency,
        orElse: () => Currency.inr,
      );
    }

    _notificationsEnabled =
        prefs.getBool(_notificationsEnabledKey) ?? _notificationsEnabled;
    _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? _isLoggedIn;
    _userName = prefs.getString(_userNameKey) ?? _userName;
    _userEmail = prefs.getString(_userEmailKey) ?? _userEmail;
    _authToken = prefs.getString(_authTokenKey);

    customReminders.clear();
    final rawReminders = prefs.getStringList(_customRemindersKey) ?? [];
    for (final raw in rawReminders) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          customReminders.add(CustomReminder.fromJson(decoded));
        } else if (decoded is Map) {
          customReminders.add(
            CustomReminder.fromJson(decoded.cast<String, dynamic>()),
          );
        }
      } catch (_) {
        // Ignore malformed entries and continue loading valid ones.
      }
    }

    notifyListeners();
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _theme.name);
    await prefs.setString(_currencyKey, _currency.name);
    await prefs.setBool(_notificationsEnabledKey, _notificationsEnabled);
    await prefs.setBool(_isLoggedInKey, _isLoggedIn);
    await prefs.setString(_userNameKey, _userName);
    await prefs.setString(_userEmailKey, _userEmail);

    if (_authToken == null || _authToken!.isEmpty) {
      await prefs.remove(_authTokenKey);
    } else {
      await prefs.setString(_authTokenKey, _authToken!);
    }

    final reminders = customReminders
        .map((r) => jsonEncode(r.toJson()))
        .toList(growable: false);
    await prefs.setStringList(_customRemindersKey, reminders);
  }

  void _saveSilently() {
    _persistState();
  }

  String get currencySymbol {
    switch (_currency) {
      case Currency.usd:
        return '\$';
      case Currency.eur:
        return '€';
      case Currency.gbp:
        return '£';
      case Currency.inr:
        return '₹';
      case Currency.jpy:
        return '¥';
    }
  }

  ThemeMode get themeMode {
    switch (_theme) {
      case AppTheme.system:
        return ThemeMode.system;
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
    }
  }

  void setTheme(AppTheme theme) {
    _theme = theme;
    notifyListeners();
    _saveSilently();
  }

  void setCurrency(Currency currency) {
    _currency = currency;
    notifyListeners();
    _saveSilently();
  }

  Future<void> addCustomReminder(
    String deviceName,
    DateTime date, {
    bool repeat = false,
  }) async {
    customReminders.add(CustomReminder(deviceName, date, repeat: repeat));
    notifyListeners();
    await _persistState();
  }

  Future<void> removeCustomReminder(String deviceName, DateTime date) async {
    customReminders.removeWhere(
      (r) =>
          r.deviceName == deviceName &&
          r.date.millisecondsSinceEpoch == date.millisecondsSinceEpoch,
    );
    notifyListeners();
    await _persistState();
  }

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
    _saveSilently();
  }

  void login(String name, String email, String token) {
    _isLoggedIn = true;
    _userName = name;
    _userEmail = email;
    _authToken = token;
    notifyListeners();
    _saveSilently();
  }

  void logout() {
    _isLoggedIn = false;
    _userName = 'Guest User';
    _userEmail = 'guest@devicecare.local';
    _authToken = null;
    notifyListeners();
    _saveSilently();
  }

  void updateUserProfile(String name, String email) {
    _userName = name;
    _userEmail = email;
    notifyListeners();
    _saveSilently();
  }
}
