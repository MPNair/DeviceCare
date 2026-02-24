import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard.dart';
import 'screens/gadget_list_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/folder_browser_screen.dart';
import 'themes/glass_theme.dart';
import 'services/settings_provider.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
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
    _screens = [
      DashboardScreen(key: _dashboardKey),
      FolderBrowserScreen(),
      GadgetListScreen(key: _gadgetListKey),
      SettingsScreen(),
    ];
  }

  void refreshAllScreens() {
    _dashboardKey.currentState?.refreshAnalytics();
    _gadgetListKey.currentState?.refreshGadgets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: GlassTheme.backgroundColor,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: GlassTheme.accentColor,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.folder_copy_rounded), label: 'Folders'),
            BottomNavigationBarItem(icon: Icon(Icons.devices_rounded), label: 'Gadgets'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
