import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/settings_provider.dart';

class LogEntryScreen extends StatefulWidget {
  final String gadgetId;

  const LogEntryScreen({required this.gadgetId});

  @override
  _LogEntryScreenState createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _typeController = TextEditingController();
  final _descController = TextEditingController();
  final _costController = TextEditingController(text: '0.0');

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  ColorScheme get _scheme => Theme.of(context).colorScheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDark ? const Color(0xFF0F172A) : _scheme.surface,
      appBar: AppBar(
        title: Text(
          'Add Service Record',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a maintenance log to track repairs and value',
                style: TextStyle(color: _scheme.onSurfaceVariant, fontSize: 14),
              ),
              SizedBox(height: 30),
              _buildTextField(
                _typeController,
                'Service Type (e.g. Screen Repair)',
                Icons.build_circle_outlined,
              ),
              SizedBox(height: 20),
              _buildTextField(
                _descController,
                'Detailed Description',
                Icons.notes_outlined,
                maxLines: 4,
              ),
              SizedBox(height: 20),
              _buildTextField(
                _costController,
                'Service Cost',
                Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _scheme.primary,
                  foregroundColor: _scheme.onPrimary,
                  minimumSize: Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: _scheme.primary.withOpacity(0.4),
                ),
                child: Text(
                  'Save Service Record',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: _scheme.onSurface),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _scheme.primary, size: 20),
            filled: true,
            fillColor: _isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _scheme.primary.withOpacity(0.6),
                width: 1,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'This field is required' : null,
        ),
      ],
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        final logData = {
          'serviceType': _typeController.text,
          'description': _descController.text,
          'cost': double.tryParse(_costController.text) ?? 0.0,
          'serviceDate': DateTime.now().toIso8601String().split('T')[0],
        };

        await _apiService.createMaintenanceLog(
          widget.gadgetId,
          logData,
          settings.authToken,
        );

        await NotificationService.syncSchedulesFromApi(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maintenance record added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to signal refresh
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
