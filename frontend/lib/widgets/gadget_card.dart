import 'package:flutter/material.dart';
import '../models/gadget.dart';
import '../themes/glass_theme.dart';
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';

class GadgetCard extends StatelessWidget {
  final Gadget gadget;
  final VoidCallback onTap;

  const GadgetCard({required this.gadget, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: GlassTheme.glassCard(
          context: context,
          height: 100,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(gadget.category),
                    color: GlassTheme.accentColor,
                    size: 35,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        gadget.name,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        gadget.brand ?? 'Unknown Brand',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${settings.currencySymbol}${gadget.currentEstimatedValue?.toStringAsFixed(2) ?? 'N/A'}',
                      style: TextStyle(color: GlassTheme.accentColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Resale Value',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'smartphone': return Icons.phone_android;
      case 'laptop': return Icons.laptop;
      case 'tablet': return Icons.tablet_android;
      case 'camera': return Icons.camera_alt;
      case 'smartwatch': return Icons.watch;
      case 'gaming console': return Icons.videogame_asset;
      case 'headphones': return Icons.headphones;
      case 'audio system': return Icons.speaker;
      case 'smart home': return Icons.home_repair_service;
      case 'drone': return Icons.toys;
      case 'e-reader': return Icons.menu_book;
      case 'peripheral': return Icons.mouse;
      case 'accessory': return Icons.extension;
      default: return Icons.devices;
    }
  }
}
