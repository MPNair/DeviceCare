import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../themes/glass_theme.dart';
import '../services/settings_provider.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark =
        settings.theme == AppTheme.dark ||
        (settings.theme == AppTheme.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Color(0xFF0F172A), Color(0xFF1E293B)]
                : [scheme.surface, scheme.primaryContainer.withOpacity(0.32)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(20),
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              SizedBox(height: 30),

              _buildProfileCard(context, isDark),
              SizedBox(height: 30),

              _buildSectionTitle('Preferences', isDark),
              _buildThemeTile(context, settings, isDark),
              _buildCurrencyTile(context, settings, isDark),
              _buildSettingTile(
                context,
                Icons.notifications,
                'Notifications',
                settings.notificationsEnabled ? 'Enabled' : 'Disabled',
                isDark,
                trailing: Switch(
                  value: settings.notificationsEnabled,
                  activeColor: GlassTheme.accentColor,
                  onChanged: (v) async {
                    settings.toggleNotifications(v);
                    await NotificationService.syncSchedulesFromApi(context);
                  },
                ),
              ),
              _buildSettingTile(
                context,
                Icons.notification_add,
                'Test Notification Now',
                'Tap to verify device notification permission',
                isDark,
                onTap: () async {
                  final ok =
                      await NotificationService.sendTestNotificationNow();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Test notification sent.'
                            : 'Notification permission denied or unavailable.',
                      ),
                      backgroundColor: ok ? Colors.green : Colors.orange,
                    ),
                  );
                },
              ),

              SizedBox(height: 25),
              _buildSectionTitle('Security & Data', isDark),
              _buildSettingTile(
                context,
                Icons.lock,
                'Security',
                'Fingerprint / FaceID',
                isDark,
                onTap: () => _showSecurityDialog(context, isDark),
              ),
              _buildSettingTile(
                context,
                Icons.cloud_sync,
                'Cloud Backup',
                'Synchronized today',
                isDark,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Simulated optimized cloud backup complete!',
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _buildSettingTile(
                context,
                Icons.file_download,
                'Export Data',
                'Generate Excel Sheet',
                isDark,
                onTap: () => _exportData(context),
              ),

              SizedBox(height: 25),
              _buildSectionTitle('Maintenance Log', isDark),
              _buildSettingTile(
                context,
                Icons.info,
                'About App',
                'v1.0.0',
                isDark,
                onTap: () => _showInfoDialog(
                  context,
                  'About App',
                  'DeviceCare v1.0.0\nBy Agentic AI',
                ),
              ),
              _buildSettingTile(
                context,
                Icons.help_center,
                'Help & Support',
                '',
                isDark,
                onTap: () => _showInfoDialog(
                  context,
                  'Help',
                  'Contact support@devicecare.io',
                ),
              ),
              _buildSettingTile(
                context,
                Icons.privacy_tip,
                'Privacy Policy',
                '',
                isDark,
                onTap: () => _showInfoDialog(
                  context,
                  'Privacy',
                  'We respect your data privacy.',
                ),
              ),

              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.8),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'Sign Out',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showSecurityDialog(BuildContext context, bool isDark) {
    final pinController = TextEditingController();
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF1E293B) : Colors.white,
        title: Text('App Security', style: TextStyle(color: scheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set a PIN to lock the application.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: 15),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              style: TextStyle(color: scheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Enter 4-digit PIN',
                labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: scheme.primary),
                ),
              ),
            ),
            SizedBox(height: 10),
            SwitchListTile(
              title: Text(
                'Biometrics',
                style: TextStyle(color: scheme.onSurface),
              ),
              value: false,
              activeColor: scheme.primary,
              onChanged: (val) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              'Save',
              style: TextStyle(color: GlassTheme.accentColor),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Security settings updated')),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final apiService = ApiService();
      final token = Provider.of<SettingsProvider>(
        context,
        listen: false,
      ).authToken;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final bytes = await apiService.exportData(token);
      Navigator.pop(context); // Close loading

      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel export generated. (Web download simulated)'),
          ),
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/DeviceCare_Export.xlsx');
        await file.writeAsBytes(bytes);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exported to ${file.path}')));
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(child: pw.Text('DeviceCare Measurement Log Report'));
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Widget _buildThemeTile(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return _buildSettingTile(
      context,
      Icons.palette,
      'Theme Mode',
      settings.theme.toString().split('.').last,
      isDark,
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? Color(0xFF1E293B) : Colors.white,
            title: Text(
              'Select Theme',
              style: TextStyle(color: scheme.onSurface),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: AppTheme.values
                  .map(
                    (t) => RadioListTile<AppTheme>(
                      title: Text(
                        t.toString().split('.').last,
                        style: TextStyle(color: scheme.onSurface),
                      ),
                      value: t,
                      groupValue: settings.theme,
                      activeColor: scheme.primary,
                      onChanged: (val) {
                        settings.setTheme(val!);
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrencyTile(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return _buildSettingTile(
      context,
      Icons.monetization_on,
      'Currency',
      settings.currency.toString().split('.').last.toUpperCase(),
      isDark,
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? Color(0xFF1E293B) : Colors.white,
            title: Text(
              'Select Currency',
              style: TextStyle(color: scheme.onSurface),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: Currency.values
                    .map(
                      (c) => RadioListTile<Currency>(
                        title: Text(
                          c.toString().split('.').last.toUpperCase(),
                          style: TextStyle(color: scheme.onSurface),
                        ),
                        value: c,
                        groupValue: settings.currency,
                        activeColor: scheme.primary,
                        onChanged: (val) {
                          settings.setCurrency(val!);
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(BuildContext context, bool isDark) {
    final scheme = Theme.of(context).colorScheme;
    return GlassTheme.glassCard(
      context: context,
      height: 100,
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: GlassTheme.accentColor,
              child: Icon(Icons.person, color: Colors.white, size: 35),
            ),
            SizedBox(width: 15),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Provider.of<SettingsProvider>(context).userName,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  Provider.of<SettingsProvider>(context).userEmail,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.edit, color: scheme.onSurfaceVariant),
              onPressed: () => _showEditProfileDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: GlassTheme.accentColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool isDark, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: GlassTheme.glassCard(
        context: context,
        height: 70,
        child: ListTile(
          leading: Icon(icon, color: scheme.onSurfaceVariant),
          title: Text(
            title,
            style: TextStyle(color: scheme.onSurface, fontSize: 16),
          ),
          subtitle: subtitle.isNotEmpty
              ? Text(
                  subtitle,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                )
              : null,
          trailing:
              trailing ?? Icon(Icons.chevron_right, color: scheme.outline),
          onTap: onTap,
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK')),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final nameController = TextEditingController(text: settings.userName);
    final emailController = TextEditingController(text: settings.userEmail);
    final isDark =
        settings.theme == AppTheme.dark ||
        (settings.theme == AppTheme.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF1E293B) : Colors.white,
        title: Text('Edit Profile', style: TextStyle(color: scheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: scheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
            TextField(
              controller: emailController,
              style: TextStyle(color: scheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              'Save',
              style: TextStyle(color: GlassTheme.accentColor),
            ),
            onPressed: () {
              settings.updateUserProfile(
                nameController.text,
                emailController.text,
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
