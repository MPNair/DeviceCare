import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/gadget.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../themes/glass_theme.dart';
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';
import 'log_entry_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_gadget_screen.dart';

class GadgetDetailScreen extends StatefulWidget {
  final Gadget gadget;

  const GadgetDetailScreen({required this.gadget});

  @override
  _GadgetDetailScreenState createState() => _GadgetDetailScreenState();
}

class _GadgetDetailScreenState extends State<GadgetDetailScreen> {
  final ApiService _apiService = ApiService();
  late Gadget _currentGadget;
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentGadget = widget.gadget;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _hasRefreshed = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  ColorScheme get _scheme => Theme.of(context).colorScheme;

  void _refreshGadget() async {
    try {
      final token = Provider.of<SettingsProvider>(
        context,
        listen: false,
      ).authToken;
      final updated = await _apiService.getGadgetById(_currentGadget.id, token);
      setState(() {
        _currentGadget = updated;
        _hasRefreshed = true;
      });
    } catch (e) {
      print('Refresh error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasRefreshed);
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [
                      _scheme.surface,
                      _scheme.primaryContainer.withOpacity(0.32),
                    ],
            ),
          ),
          child: CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                stretch: true,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context, _hasRefreshed),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isDark
                            ? Colors.white12
                            : _scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.qr_code, size: 20),
                    ),
                    onPressed: _showLabelDialog,
                  ),
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isDark
                            ? Colors.white12
                            : _scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit, size: 20),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddGadgetScreen(gadget: _currentGadget),
                        ),
                      );
                      if (result == true) _refreshGadget();
                    },
                  ),
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                    ),
                    onPressed: _showDeleteDialog,
                  ),
                  SizedBox(width: 10),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  title: Text(
                    _currentGadget.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _currentGadget.imageUrls.isEmpty
                          ? Center(
                              child: Hero(
                                tag: 'gadget_${_currentGadget.id}',
                                child: Icon(
                                  _getCategoryIcon(_currentGadget.category),
                                  size: 120,
                                  color: GlassTheme.accentColor.withOpacity(
                                    0.4,
                                  ),
                                ),
                              ),
                            )
                          : Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                PageView.builder(
                                  controller: _pageController,
                                  itemCount: _currentGadget.imageUrls.length,
                                  onPageChanged: (index) =>
                                      setState(() => _currentPage = index),
                                  itemBuilder: (context, index) {
                                    final url = _currentGadget.imageUrls[index];
                                    return (url.startsWith('http') ||
                                            url.startsWith('https') ||
                                            url.startsWith('blob:'))
                                        ? Image.network(url, fit: BoxFit.cover)
                                        : (kIsWeb
                                              ? Container(
                                                  color: _scheme
                                                      .surfaceContainerHighest,
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.image_not_supported,
                                                      color: _scheme.outline,
                                                      size: 50,
                                                    ),
                                                  ),
                                                )
                                              : Image.file(
                                                  File(url),
                                                  fit: BoxFit.cover,
                                                ));
                                  },
                                ),
                                Positioned(
                                  bottom: 60,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      _currentGadget.imageUrls.length,
                                      (index) => Container(
                                        width: 8,
                                        height: 8,
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _currentPage == index
                                              ? GlassTheme.accentColor
                                              : _scheme.outline.withOpacity(
                                                  0.6,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      // Overlay for better text visibility
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              (_isDark ? Colors.black : _scheme.scrim)
                                  .withOpacity(0.55),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                backgroundColor: Colors.transparent,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildConditionBadge(),
                      SizedBox(height: 25),

                      _buildSectionTitle(Icons.info_outline, 'Device Profile'),
                      SizedBox(height: 12),
                      _buildDetailCard([
                        _buildInfoRow(
                          Icons.branding_watermark_outlined,
                          'Brand',
                          _currentGadget.brand ?? 'N/A',
                        ),
                        _buildInfoRow(
                          Icons.model_training_outlined,
                          'Model',
                          _currentGadget.model ?? 'N/A',
                        ),
                        _buildInfoRow(
                          Icons.storage_outlined,
                          'Storage',
                          _currentGadget.storageCapacity ?? 'N/A',
                        ),
                        _buildInfoRow(
                          Icons.palette_outlined,
                          'Color',
                          _currentGadget.color ?? 'N/A',
                        ),
                        _buildInfoRow(
                          Icons.qr_code_scanner_outlined,
                          'Serial No',
                          _currentGadget.serialNumber ?? 'N/A',
                        ),
                      ]),

                      SizedBox(height: 25),
                      _buildSectionTitle(
                        Icons.payments_outlined,
                        'Financials & Warranty',
                      ),
                      SizedBox(height: 12),
                      _buildDetailCard([
                        _buildInfoRow(
                          Icons.store_outlined,
                          'Store',
                          _currentGadget.purchaseStore ?? 'N/A',
                        ),
                        _buildInfoRow(
                          Icons.calendar_today_outlined,
                          'Purchase Date',
                          dateFormat.format(_currentGadget.purchaseDate),
                        ),
                        _buildInfoRow(
                          Icons.price_check_outlined,
                          'Purchase Price',
                          '${settings.currencySymbol ?? '\$'}${_currentGadget.purchasePrice.toStringAsFixed(2)}',
                        ),
                        _buildInfoRow(
                          Icons.verified_user_outlined,
                          'Warranty Expiry',
                          _currentGadget.warrantyExpiryDate != null
                              ? dateFormat.format(
                                  _currentGadget.warrantyExpiryDate!,
                                )
                              : 'N/A',
                        ),
                      ]),

                      if (_currentGadget.documents.isNotEmpty) ...[
                        SizedBox(height: 25),
                        _buildSectionTitle(
                          Icons.description_outlined,
                          'Documents',
                        ),
                        SizedBox(height: 12),
                        _buildDocumentsGrid(),
                      ],

                      if (_currentGadget.customFields.isNotEmpty) ...[
                        SizedBox(height: 25),
                        _buildSectionTitle(
                          Icons.dynamic_form_outlined,
                          'Custom Metadata',
                        ),
                        SizedBox(height: 12),
                        _buildDetailCard(
                          _currentGadget.customFields.entries
                              .map(
                                (e) => _buildInfoRow(
                                  Icons.label_important_outline,
                                  e.key.toString(),
                                  e.value.toString(),
                                ),
                              )
                              .toList(),
                        ),
                      ],

                      SizedBox(height: 25),
                      _buildSectionTitle(
                        Icons.trending_down_outlined,
                        'Value Insight',
                      ),
                      SizedBox(height: 12),
                      GlassTheme.glassCard(
                        context: context,
                        height: 120,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${settings.currencySymbol ?? '\$'}${_currentGadget.currentEstimatedValue?.toStringAsFixed(2) ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: GlassTheme.accentColor,
                                    ),
                                  ),
                                  Text(
                                    'Current Market Estimation',
                                    style: TextStyle(
                                      color: _scheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 60,
                              color: _scheme.outlineVariant,
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${((_currentGadget.currentEstimatedValue ?? 0) / _currentGadget.purchasePrice * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                  Text(
                                    'Retention Rate',
                                    style: TextStyle(
                                      color: _scheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      _buildSectionTitle(
                        Icons.insights_rounded,
                        'Resale & Maintenance Insights',
                      ),
                      SizedBox(height: 12),
                      _buildInsightsCard(settings),

                      SizedBox(height: 30),
                      _buildSectionTitle(
                        Icons.history_outlined,
                        'Maintenance History',
                      ),
                      SizedBox(height: 12),
                      _buildMaintenanceHistory(settings),
                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    LogEntryScreen(gadgetId: _currentGadget.id),
              ),
            );
            if (result == true) _refreshGadget();
          },
          icon: Icon(Icons.add_task),
          label: Text('Record Maintenance'),
          backgroundColor: GlassTheme.accentColor,
        ),
      ),
    );
  }

  Widget _buildConditionBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getConditionColor(
          _currentGadget.conditionScore,
        ).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getConditionColor(
            _currentGadget.conditionScore,
          ).withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars,
            size: 16,
            color: _getConditionColor(_currentGadget.conditionScore),
          ),
          SizedBox(width: 6),
          Text(
            'Condition: ${_currentGadget.conditionScore}/10',
            style: TextStyle(
              color: _getConditionColor(_currentGadget.conditionScore),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          Container(width: 1, height: 12, color: _scheme.outline),
          SizedBox(width: 8),
          Text(
            _currentGadget.status.toUpperCase(),
            style: TextStyle(
              color: _scheme.onSurfaceVariant,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Color _getConditionColor(int? score) {
    if (score == null) return Colors.grey;
    if (score >= 8) return Colors.greenAccent;
    if (score >= 5) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Widget _buildDetailCard(List<Widget> children) {
    return GlassTheme.glassCard(
      context: context,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _scheme.onSurfaceVariant),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _scheme.onSurface,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isLink ? GlassTheme.accentColor : _scheme.onSurfaceVariant,
            ),
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(color: _scheme.onSurfaceVariant, fontSize: 14),
            ),
            Spacer(),
            Text(
              value,
              style: TextStyle(
                color: isLink ? GlassTheme.accentColor : _scheme.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openUrl(String url) {
    print('Opening URL: $url');
    // In real app, use url_launcher
  }

  void _showLabelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Gadget QR Label',
          style: TextStyle(color: _scheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=https://devicecare.io/app/gadget/${_currentGadget.id}',
                width: 150,
                height: 150,
              ),
            ),
            SizedBox(height: 20),
            Text(
              _currentGadget.name,
              style: TextStyle(
                color: _scheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'SN: ${_currentGadget.serialNumber ?? 'N/A'}',
              style: TextStyle(color: _scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Simulate print
              print('Printing label for ${_currentGadget.name}');
              Navigator.pop(context);
            },
            icon: Icon(Icons.print),
            label: Text('Print Label'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GlassTheme.accentColor,
              foregroundColor: _scheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Delete Gadget?',
          style: TextStyle(color: _scheme.onSurface),
        ),
        content: Text(
          'This will permanently remove the device and all history. Proceed?',
          style: TextStyle(color: _scheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: _scheme.onPrimary,
            ),
            child: Text('Delete'),
            onPressed: () async {
              final token = Provider.of<SettingsProvider>(
                context,
                listen: false,
              ).authToken;
              await _apiService.deleteGadget(_currentGadget.id, token);
              await NotificationService.syncSchedulesFromApi(context);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Go back to list with refresh
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceHistory(SettingsProvider settings) {
    if (_currentGadget.logs.isEmpty) {
      return GlassTheme.glassCard(
        context: context,
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, color: _scheme.outlineVariant, size: 40),
              SizedBox(height: 12),
              Text(
                'No service records found',
                style: TextStyle(
                  color: _scheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Keep your device value high by tracking repairs',
                style: TextStyle(color: _scheme.outlineVariant, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy');
    return Column(
      children: _currentGadget.logs.map((log) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassTheme.glassCard(
            context: context,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          log.serviceType,
                          style: TextStyle(
                            color: _scheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${settings.currencySymbol ?? '\$'}${log.cost.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (log.description != null &&
                      log.description!.isNotEmpty) ...[
                    Text(
                      log.description!,
                      style: TextStyle(
                        color: _scheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: _scheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 6),
                      Text(
                        dateFormat.format(log.serviceDate),
                        style: TextStyle(
                          color: _scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      if (log.technicianDetails != null) ...[
                        SizedBox(width: 16),
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: _scheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 6),
                        Text(
                          log.technicianDetails!,
                          style: TextStyle(
                            color: _scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsightsCard(SettingsProvider settings) {
    final purchaseDate = _currentGadget.purchaseDate;
    final ageMonths = (DateTime.now().difference(purchaseDate).inDays / 30.44);

    // Optimal window: 22-26 months
    bool isOptimalWindow = ageMonths >= 22 && ageMonths <= 26;

    final maintenanceCost = _currentGadget.logs.fold(
      0.0,
      (sum, log) => sum + log.cost,
    );
    final currentVal = _currentGadget.currentEstimatedValue ?? 0.0;
    bool highMaintenance =
        currentVal > 0 && (maintenanceCost / currentVal) >= 0.4;

    return GlassTheme.glassCard(
      context: context,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            if (isOptimalWindow)
              _buildInsightRow(
                Icons.shopping_bag_rounded,
                'Optimal Resale Window',
                'Now is the best time to sell for maximum value retention.',
                Colors.greenAccent,
              ),
            if (highMaintenance)
              _buildInsightRow(
                Icons.warning_amber_rounded,
                'High Maintenance Cost',
                'Repairs have exceeded 40% of current value. Consider replacement.',
                Colors.orangeAccent,
              ),
            if (!isOptimalWindow && !highMaintenance)
              _buildInsightRow(
                Icons.check_circle_outline,
                'Device Status',
                'Your device is in a stable value retention phase.',
                _scheme.onSurfaceVariant,
              ),
            SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () {
                _launchMarketplace();
              },
              icon: Icon(Icons.outbound_rounded),
              label: Text('Check Marketplace Quotes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlassTheme.accentColor.withOpacity(0.2),
                foregroundColor: _scheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(
    IconData icon,
    String title,
    String message,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(color: _scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: _currentGadget.documents.length,
      itemBuilder: (context, index) {
        final doc = _currentGadget.documents[index];
        final String url = doc['url'] ?? '';
        final String name = doc['name'] ?? (url.split(RegExp(r'[/\\]')).last);

        return InkWell(
          onTap: () => _openUrl(url),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _scheme.outlineVariant.withOpacity(0.65),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  color: GlassTheme.accentColor,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: _scheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  void _launchMarketplace() {
    final brand = _slugify(_currentGadget.brand ?? '');
    final model = _slugify(_currentGadget.model ?? '');
    final storage = _slugify(_currentGadget.storageCapacity ?? '');
    final color = _slugify(_currentGadget.color ?? '');

    String baseUrl = 'https://www.cashify.in/sell-old-mobile-phone';
    String category = _currentGadget.category.toLowerCase();

    if (category.contains('laptop')) {
      baseUrl = 'https://www.cashify.in/sell-old-laptop';
    } else if (category.contains('tablet')) {
      baseUrl = 'https://www.cashify.in/sell-old-tablet';
    } else if (category.contains('watch')) {
      baseUrl = 'https://www.cashify.in/sell-old-smart-watch';
    } else if (category.contains('camera')) {
      baseUrl = 'https://www.cashify.in/sell-old-camera';
    }

    // Try to construct a direct slug if enough info is present
    Uri? url;
    if (brand.isNotEmpty && model.isNotEmpty) {
      String slug = 'used-$brand-$model';
      if (storage.isNotEmpty) slug += '-$storage';
      if (color.isNotEmpty) slug += '-$color';

      // Attempt direct URL
      url = Uri.tryParse('$baseUrl/$slug');
    } else {
      // Fallback to search if not enough info
      final query = [
        brand,
        model,
        storage,
        color,
      ].where((s) => s.isNotEmpty).join('+');
      url = Uri.tryParse('$baseUrl/search?q=$query');
    }

    if (url != null) {
      launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not build marketplace link.')),
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'smartphone':
        return Icons.phone_android;
      case 'laptop':
        return Icons.laptop;
      case 'tablet':
        return Icons.tablet_android;
      case 'camera':
        return Icons.camera_alt;
      case 'smartwatch':
        return Icons.watch;
      case 'gaming console':
        return Icons.videogame_asset;
      case 'headphones':
        return Icons.headphones;
      case 'audio system':
        return Icons.speaker;
      case 'smart home':
        return Icons.home_repair_service;
      case 'drone':
        return Icons.toys;
      case 'e-reader':
        return Icons.menu_book;
      case 'peripheral':
        return Icons.mouse;
      case 'accessory':
        return Icons.extension;
      default:
        return Icons.devices;
    }
  }
}
