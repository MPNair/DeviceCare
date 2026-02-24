import 'package:flutter/material.dart';

enum AppTheme { system, light, dark }
enum Currency { usd, eur, gbp, inr, jpy }

class SettingsProvider with ChangeNotifier {
  AppTheme _theme = AppTheme.dark;
  Currency _currency = Currency.inr;
  bool _notificationsEnabled = true;
  bool _isLoggedIn = false;
  String _userName = 'Guest User';
  String _userEmail = 'guest@devicecare.io';
  String? _authToken;

  AppTheme get theme => _theme;
  Currency get currency => _currency;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String? get authToken => _authToken;

  String get currencySymbol {
    switch (_currency) {
      case Currency.usd: return '\$';
      case Currency.eur: return '€';
      case Currency.gbp: return '£';
      case Currency.inr: return '₹';
      case Currency.jpy: return '¥';
    }
  }

  ThemeMode get themeMode {
    switch (_theme) {
      case AppTheme.system: return ThemeMode.system;
      case AppTheme.light: return ThemeMode.light;
      case AppTheme.dark: return ThemeMode.dark;
    }
  }

  void setTheme(AppTheme theme) {
    _theme = theme;
    notifyListeners();
  }

  void setCurrency(Currency currency) {
    _currency = currency;
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void login(String name, String email, String token) {
    _isLoggedIn = true;
    _userName = name;
    _userEmail = email;
    _authToken = token;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _userName = 'Guest User';
    _userEmail = 'guest@devicecare.io';
    _authToken = null;
    notifyListeners();
  }

  void updateUserProfile(String name, String email) {
    _userName = name;
    _userEmail = email;
    notifyListeners();
  }
}
