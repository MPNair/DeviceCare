import 'package:flutter/material.dart';
import '../models/gadget.dart';
import '../services/api_service.dart';
import '../widgets/gadget_card.dart';
import 'add_gadget_screen.dart';
import 'gadget_detail_screen.dart';
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';
import '../main.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class GadgetListScreen extends StatefulWidget {
  const GadgetListScreen({Key? key}) : super(key: key);

  @override
  GadgetListScreenState createState() => GadgetListScreenState();
}

class GadgetListScreenState extends State<GadgetListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Gadget>> _gadgetsFuture;

  @override
  void initState() {
    super.initState();
    refreshGadgets();
  }

  void refreshGadgets() {
    final token = Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).authToken;
    setState(() {
      _gadgetsFuture = _apiService.getGadgets(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Gadgets', style: TextStyle(color: scheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: refreshGadgets),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [scheme.surface, scheme.primaryContainer.withOpacity(0.3)],
          ),
        ),
        child: FutureBuilder<List<Gadget>>(
          future: _gadgetsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 60,
                      color: scheme.outline,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'No gadgets found. Add one!',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => refreshGadgets(),
              child: ListView.builder(
                padding: EdgeInsets.all(20),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final gadget = snapshot.data![index];
                  return GadgetCard(
                    gadget: gadget,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GadgetDetailScreen(gadget: gadget),
                        ),
                      );
                      if (result == true) {
                        refreshGadgets();
                        // Refresh dashboard when gadget is edited/deleted
                        final mainNav = context
                            .findAncestorStateOfType<MainNavigationState>();
                        mainNav?.refreshAllScreens();
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddGadgetScreen()),
          );
          if (result == true) {
            refreshGadgets();
            // Notify parent MainNavigation to refresh dashboard too
            final mainNav = context
                .findAncestorStateOfType<MainNavigationState>();
            mainNav?.refreshAllScreens();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: scheme.primary,
      ),
    );
  }
}
