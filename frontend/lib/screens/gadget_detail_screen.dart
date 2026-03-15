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
                expandedHeight: 120, // Reduced from 320
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
                  // Background removed entirely for standard top bar
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

                      if (_currentGadget.imageUrls.isNotEmpty) ...[
                        _buildSectionTitle(
                          Icons.photo_library_outlined,
                          'Gallery',
                        ),
                        SizedBox(height: 12),
                        _buildGallery(),
                        SizedBox(height: 25),
                      ],

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
                        Icons.notifications_active_outlined,
                        'Custom Notifications',
                      ),
                      SizedBox(height: 12),
                      _buildCustomNotificationsCard(settings),

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

  void _openUrl(String url) async {
    final fullUrl = url.startsWith('/uploads')
        ? '${ApiService.hostUrl}$url'
        : url;
    final uri = Uri.parse(fullUrl);

    if (url.startsWith('http') ||
        url.startsWith('https') ||
        url.startsWith('/uploads')) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch document URL')),
        );
      }
    } else {
      // Handle local file
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Opening local file: $url')));
    }
  }

  void _showLabelDialog() {
    // Unique, human-readable payload so scanning shows device name, model, storage
    final name = _currentGadget.name;
    final model = _currentGadget.model ?? 'N/A';
    final storage = _currentGadget.storageCapacity ?? 'N/A';
    final serial = _currentGadget.serialNumber ?? 'N/A';
    final qrText =
        'DeviceCare\n'
        'Name: $name\n'
        'Model: $model\n'
        'Storage: $storage\n'
        'Serial: $serial\n'
        'ID: ${_currentGadget.id}';
    final qrDataEncoded = Uri.encodeComponent(qrText);

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
                'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=$qrDataEncoded',
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
              label: Text('Check Quotes on Cashify.in'),
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

  Widget _buildCustomNotificationsCard(SettingsProvider settings) {
    final deviceName = _currentGadget.name;
    final remindersForDevice = settings.customReminders
        .where((r) => r.deviceName == deviceName)
        .toList();

    return GlassTheme.glassCard(
      context: context,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showScheduleDialog(settings),
              icon: Icon(Icons.add_alarm),
              label: Text('Schedule notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlassTheme.accentColor.withOpacity(0.2),
                foregroundColor: _scheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (remindersForDevice.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'Scheduled reminders',
                style: TextStyle(
                  color: _scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              ...remindersForDevice.map((r) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    DateFormat('yMMMd • HH:mm').format(r.date),
                    style: TextStyle(color: _scheme.onSurface, fontSize: 13),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () async {
                      await settings.removeCustomReminder(r.deviceName, r.date);
                      await NotificationService.cancelCustomNotification(
                        r.deviceName,
                        r.date,
                      );
                      setState(() {});
                    },
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  void _showScheduleDialog(SettingsProvider settings) {
    final parentContext = context;
    final deviceName = _currentGadget.name;
    DateTime? localScheduledDate;
    TimeOfDay? localScheduledTime = TimeOfDay.now();
    bool localRepeat = false;
    bool isScheduling = false;

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text('Schedule notification'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.calendar_today),
                    title: Text(
                      localScheduledDate == null
                          ? 'Select date'
                          : DateFormat('yMMMd').format(localScheduledDate!),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: dialogContext,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() => localScheduledDate = date);
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.access_time),
                    title: Text(
                      localScheduledTime == null
                          ? 'Select time'
                          : localScheduledTime!.format(dialogContext),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: dialogContext,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setDialogState(() => localScheduledTime = time);
                      }
                    },
                  ),
                  CheckboxListTile(
                    value: localRepeat,
                    onChanged: (v) =>
                        setDialogState(() => localRepeat = v ?? false),
                    title: Text('Repeat daily'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isScheduling
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isScheduling
                      ? null
                      : () async {
                          if (localScheduledDate == null ||
                              localScheduledTime == null) {
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(content: Text('Select date and time.')),
                            );
                            return;
                          }
                          final scheduledDateTime = DateTime(
                            localScheduledDate!.year,
                            localScheduledDate!.month,
                            localScheduledDate!.day,
                            localScheduledTime!.hour,
                            localScheduledTime!.minute,
                          );
                          if (scheduledDateTime.isBefore(DateTime.now())) {
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please choose a future date and time.',
                                ),
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isScheduling = true);
                          try {
                            await NotificationService.addCustomReminderToCalendar(
                              parentContext,
                              scheduledDateTime,
                              deviceName,
                              repeat: localRepeat,
                            );
                            await NotificationService.scheduleDeviceNotification(
                              parentContext,
                              scheduledDateTime,
                              repeat: localRepeat,
                              deviceName: deviceName,
                            );
                          } catch (e) {
                            setDialogState(() => isScheduling = false);
                            if (parentContext.mounted) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not schedule: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          if (parentContext.mounted) {
                            Navigator.of(dialogContext).pop();
                            setState(() {});
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Reminder scheduled for $deviceName on ${DateFormat('yMMMd').add_jm().format(scheduledDateTime)}.',
                                ),
                              ),
                            );
                          }
                        },
                  child: isScheduling
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGallery() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        itemCount: _currentGadget.imageUrls.length,
        itemBuilder: (context, index) {
          final url = _currentGadget.imageUrls[index];
          return GestureDetector(
            onTap: () => _showMediaViewer(index),
            child: Container(
              width: 120,
              margin: EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: _isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _scheme.outlineVariant.withOpacity(0.65),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child:
                    (url.startsWith('http') ||
                        url.startsWith('https') ||
                        url.startsWith('blob:'))
                    ? Image.network(url, fit: BoxFit.cover)
                    : (url.startsWith('/uploads')
                          ? Image.network(
                              '${ApiService.hostUrl}$url',
                              fit: BoxFit.cover,
                            )
                          : (kIsWeb
                                ? Container(
                                    color: _scheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: _scheme.outline,
                                      size: 40,
                                    ),
                                  )
                                : Image.file(File(url), fit: BoxFit.cover))),
              ),
            ),
          );
        },
      ),
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

  void _showMediaViewer(int initialIndex) {
    if (_currentGadget.imageUrls.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        return Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: _currentGadget.imageUrls.length,
              itemBuilder: (context, index) {
                final url = _currentGadget.imageUrls[index];
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child:
                        (url.startsWith('http') ||
                            url.startsWith('https') ||
                            url.startsWith('blob:'))
                        ? Image.network(url)
                        : (url.startsWith('/uploads')
                              ? Image.network('${ApiService.hostUrl}$url')
                              : (kIsWeb
                                    ? Container(
                                        color: _scheme.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: _scheme.outline,
                                          size: 50,
                                        ),
                                      )
                                    : Image.file(File(url)))),
                  ),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        );
      },
    );
  }

  void _launchMarketplace() {
    // Cashify verified format: /{category}/sell-{brand} — navigates to brand model selection
    final category = _currentGadget.category.toLowerCase();
    final String categoryPath = _cashifyCategoryPath(category);

    final brand = (_currentGadget.brand ?? '').trim().toLowerCase();
    String finalPath = categoryPath;
    if (brand.isNotEmpty) {
      var brandSlug = brand
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'-+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      if (brand.contains('hp') || brand.contains('compaq')) {
        brandSlug = 'hp-compaq';
      }
      finalPath = '$categoryPath/sell-$brandSlug';
    }

    final marketplaceUri = Uri.https('www.cashify.in', finalPath);
    _openUrl(marketplaceUri.toString());
  }

  /// Maps app device types to Cashify category path. Covers all device types.
  String _cashifyCategoryPath(String category) {
    if (category.contains('mobile') ||
        category.contains('phone') ||
        category.contains('smartphone')) {
      return '/sell-old-mobile-phone';
    }
    if (category.contains('laptop')) return '/sell-old-laptop';
    if (category.contains('tablet') ||
        category.contains('e-reader') ||
        category.contains('ereader')) {
      return '/sell-old-tablet';
    }
    if (category.contains('watch') || category.contains('smartwatch')) {
      return '/sell-old-smart-watch';
    }
    if (category.contains('camera') || category.contains('drone')) {
      return '/sell-old-dslr-camera';
    }
    if (category.contains('headphone') ||
        category.contains('earbud') ||
        category.contains('audio') ||
        category.contains('speaker')) {
      return '/sell-old-earbuds';
    }
    if (category.contains('smart home')) return '/sell-old-smart-speaker';
    if (category.contains('television') ||
        category.contains('tv') ||
        category.contains('gaming') ||
        category.contains('console')) {
      return '/sell-old-television';
    }
    if (category.contains('peripheral') || category.contains('accessory')) {
      return '/sell-old-earbuds';
    }
    // Default for Other and any uncategorized device type
    return '/sell-old-mobile-phone';
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
