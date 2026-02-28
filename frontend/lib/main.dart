import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard.dart';
import 'screens/gadget_list_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/folder_browser_screen.dart';
import 'screens/calendar_screen.dart';
import 'themes/glass_theme.dart';
import 'services/settings_provider.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => SettingsProvider())],
      child: DeviceCareApp(),
    ),
  );
}

class DeviceCareApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return MaterialApp(
      title: 'Digital Maintenance Log',
      debugShowCheckedModeBanner: false,
      theme: GlassTheme.lightTheme,
      darkTheme: GlassTheme.darkTheme,
      themeMode: settings.themeMode,
      home: settings.isLoggedIn ? MainNavigation() : LoginScreen(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  MainNavigationState createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey();
  final GlobalKey<GadgetListScreenState> _gadgetListKey = GlobalKey();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    NotificationService.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.syncSchedulesFromApi(context);
    });

    _screens = [
      DashboardScreen(key: _dashboardKey),
      FolderBrowserScreen(),
      GadgetListScreen(key: _gadgetListKey),
      CalendarScreen(),
      SettingsScreen(),
    ];
  }

  void refreshAllScreens() {
    _dashboardKey.currentState?.refreshAnalytics();
    _gadgetListKey.currentState?.refreshGadgets();
    NotificationService.syncSchedulesFromApi(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? GlassTheme.backgroundColor : Colors.white,
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withOpacity(isDark ? 0.2 : 0.5),
              width: 0.7,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: scheme.primary,
          unselectedItemColor: isDark
              ? Colors.white54
              : scheme.onSurfaceVariant,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_copy_rounded),
              label: 'Folders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.devices_rounded),
              label: 'Gadgets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
