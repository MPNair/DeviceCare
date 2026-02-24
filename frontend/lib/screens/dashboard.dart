import 'package:flutter/material.dart';
import '../themes/glass_theme.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';
import '../models/gadget.dart';
import 'gadget_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  
  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    final token = Provider.of<SettingsProvider>(context, listen: false).authToken;
    _analyticsFuture = _apiService.getAnalytics(token);
  }
  
  void refreshAnalytics() {
    final token = Provider.of<SettingsProvider>(context, listen: false).authToken;
    setState(() {
      _analyticsFuture = _apiService.getAnalytics(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [Color(0xFF0F172A), Color(0xFF1E293B)]
              : [Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
               setState(() { _analyticsFuture = _apiService.getAnalytics(settings.authToken); });
            },
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Digital Log',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Maintenance & Resale Tracking',
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                        ),
                        SizedBox(height: 30),
                        FutureBuilder<Map<String, dynamic>>(
                          future: _analyticsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.redAccent)));
                            }
                            
                            final summary = snapshot.data!['summary'];
                            final trends = snapshot.data!['marketTrends'];
                            
                            return Column(
                              children: [
                                GlassTheme.glassCard(
                                  context: context,
                                  height: 220,
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildStatRow('Total Value', '${settings.currencySymbol}${summary['totalCurrentValue'].toStringAsFixed(2)}', GlassTheme.accentColor, isDark),
                                        _buildStatRow('Avg Retention', '${summary['averageRetentionRate'] ?? 0}%', Colors.greenAccent, isDark),
                                        _buildStatRow('Total Gadgets', summary['totalGadgets'].toString(), isDark ? Colors.white : Colors.black87, isDark),
                                        _buildStatRow('Maintenance Load', '${summary['maintenanceLoad'] ?? 0}%', Colors.orange, isDark),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 25),
                                ..._buildUpcomingAlerts(snapshot.data!['upcomingDeadlines'], isDark),
                                SizedBox(height: 25),
                                ...trends != null ? [
                                  Text('Market Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                  SizedBox(height: 15),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTrendCard(context, 'Demand', '${trends['demandShift']}%', double.parse(trends['demandShift'].toString()) > 0, isDark),
                                      ),
                                      SizedBox(width: 15),
                                      Expanded(
                                        child: _buildTrendCard(context, 'Sustainability', trends['sustainabilityScore'].toString(), true, isDark),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 25),
                                ] : [],
                                _buildCategoryDistribution(context, snapshot.data!['categoryDistribution'], isDark),
                                SizedBox(height: 50),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16)),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTrendCard(BuildContext context, String label, String value, bool positive, bool isDark) {
    return GlassTheme.glassCard(
      context: context,
      height: 90,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(positive ? Icons.trending_up : Icons.trending_down, color: positive ? Colors.greenAccent : Colors.redAccent, size: 20),
              SizedBox(width: 5),
              Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(label, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution(BuildContext context, Map<String, dynamic> data, bool isDark) {
    if (data.isEmpty) return Container();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        SizedBox(height: 15),
        GlassTheme.glassCard(
          context: context,
          height: 150,
          child: ListView(
             padding: EdgeInsets.all(15),
             children: data.entries.map((e) => Padding(
               padding: const EdgeInsets.symmetric(vertical: 4.0),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(e.key, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                   Text('${e.value} devices', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                 ],
               ),
             )).toList(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildUpcomingAlerts(List<dynamic>? deadlines, bool isDark) {
    if (deadlines == null || deadlines.isEmpty) return [];
    
    return [
      Text('Critical Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
      SizedBox(height: 15),
      ...deadlines.map((d) {
        final type = d['type'];
        final color = type == 'maintenance_alert' ? Colors.orangeAccent : 
                      (type == 'resale_opportunity' ? Colors.greenAccent : Colors.blueAccent);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassTheme.glassCard(
            context: context,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(_getAlertIcon(type), color: color, size: 20),
              ),
              title: Text(d['gadgetName'], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(d['message'] ?? (type == 'warranty' ? 'Warranty expires in ${d['daysLeft']} days' : ''), style: TextStyle(color: Colors.white70, fontSize: 12)),
              trailing: Icon(Icons.chevron_right, color: Colors.white24),
              onTap: () => _navigateToGadget(d['gadgetId']),
            ),
          ),
        );
      }).toList(),
    ];
  }

  void _navigateToGadget(String id) async {
    try {
      final token = Provider.of<SettingsProvider>(context, listen: false).authToken;
      final gadget = await _apiService.getGadgetById(id, token);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GadgetDetailScreen(gadget: gadget)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open gadget: $e')));
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'maintenance_alert': return Icons.warning_rounded;
      case 'resale_opportunity': return Icons.shopping_cart_checkout_rounded;
      case 'warranty': return Icons.verified_user_rounded;
      default: return Icons.notifications_active_rounded;
    }
  }
}
