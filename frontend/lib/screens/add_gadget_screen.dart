import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/gadget.dart';
import '../themes/glass_theme.dart';
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';
import '../services/scanner_service.dart';
import '../models/folder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddGadgetScreen extends StatefulWidget {
  final Gadget? gadget; // If provided, we are in Edit mode
  final String? initialSerialNumber;

  const AddGadgetScreen({this.gadget, this.initialSerialNumber});

  @override
  _AddGadgetScreenState createState() => _AddGadgetScreenState();
}

class _AddGadgetScreenState extends State<AddGadgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _priceController;
  late TextEditingController _serialController;
  late TextEditingController _warrantyMonthsController;
  late TextEditingController _supplierController;
  late TextEditingController _storageController;
  late TextEditingController _colorController;
  late TextEditingController _specsController;
  late TextEditingController _roomController;
  late TextEditingController _tagsController;

  late String _category;
  late String _ownershipStatus;
  late double _conditionScore;
  late DateTime _purchaseDate;
  List<Folder> _availableFolders = [];
  String? _selectedFolderId;
  List<String> _imageUrls = [];
  List<Map<String, dynamic>> _documents = [];
  Map<String, dynamic> _customFields = {};

  final List<String> _categories = [
    'Smartphone',
    'Laptop',
    'Tablet',
    'Camera',
    'Smartwatch',
    'Gaming Console',
    'Headphones',
    'Audio System',
    'Smart Home',
    'Drone',
    'E-reader',
    'Peripheral',
    'Accessory',
    'Other',
  ];

  final List<String> _ownershipOptions = [
    'First Hand',
    'Second Hand',
    'Refurbished',
    'Gift',
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.gadget;
    _nameController = TextEditingController(text: g?.name ?? '');
    _brandController = TextEditingController(text: g?.brand ?? '');
    _modelController = TextEditingController(text: g?.model ?? '');
    _priceController = TextEditingController(
      text: g?.purchasePrice.toString() ?? '',
    );
    _serialController = TextEditingController(
      text: widget.gadget?.serialNumber ?? widget.initialSerialNumber ?? '',
    );

    int warrantyMonths = 0;
    if (g != null && g.warrantyExpiryDate != null) {
      warrantyMonths =
          (g.warrantyExpiryDate!.difference(g.purchaseDate).inDays / 30.44)
              .round();
    }
    _warrantyMonthsController = TextEditingController(
      text: warrantyMonths > 0 ? warrantyMonths.toString() : '',
    );
    _supplierController = TextEditingController(text: g?.purchaseStore ?? '');
    _storageController = TextEditingController(text: g?.storageCapacity ?? '');
    _colorController = TextEditingController(text: g?.color ?? '');
    _specsController = TextEditingController(
      text: g?.technicalSpecs != null ? jsonEncode(g!.technicalSpecs) : '',
    );
    _roomController = TextEditingController(text: g?.room ?? '');
    _tagsController = TextEditingController(text: g?.tags.join(', ') ?? '');

    _category = g?.category ?? 'Smartphone';
    _ownershipStatus = g?.ownershipStatus ?? 'First Hand';
    _selectedFolderId = g?.folderId;
    _conditionScore = g?.conditionScore.toDouble() ?? 10.0;
    _purchaseDate = g?.purchaseDate ?? DateTime.now();
    _imageUrls = g?.imageUrls ?? [];
    _documents = List<Map<String, dynamic>>.from(g?.documents ?? []);
    _customFields = Map<String, dynamic>.from(g?.customFields ?? {});

    _fetchAvailableFolders();
  }

  Future<void> _fetchAvailableFolders() async {
    try {
      final token = Provider.of<SettingsProvider>(
        context,
        listen: false,
      ).authToken;
      final folders = await _apiService.getFolders(token);
      if (mounted) {
        setState(() {
          _availableFolders = folders;
        });
      }
    } catch (e) {
      debugPrint('Error fetching folders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.gadget != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Gadget' : 'Add New Gadget'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isEdit)
            IconButton(
              icon: Icon(Icons.file_upload_outlined),
              tooltip: 'Import CSV',
              onPressed: _importCSV,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Basic Information'),
                SizedBox(height: 10),
                _buildTextField(_nameController, 'Gadget Name', Icons.devices),
                SizedBox(height: 15),
                _buildDropdown(
                  'Category',
                  _category,
                  _categories,
                  (val) => setState(() => _category = val!),
                ),
                SizedBox(height: 15),
                _buildFolderDropdown(),
                SizedBox(height: 15),
                _buildTextField(
                  _roomController,
                  'Room / Location',
                  Icons.room,
                  required: false,
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _brandController,
                        'Brand',
                        Icons.branding_watermark,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: _buildTextField(
                        _modelController,
                        'Model',
                        Icons.model_training,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _storageController,
                        'Storage (e.g. 256GB)',
                        Icons.storage,
                        required: false,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: _buildTextField(
                        _colorController,
                        'Color',
                        Icons.palette,
                        required: false,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                _buildTextField(
                  _serialController,
                  'Serial Number',
                  Icons.qr_code,
                  required: false,
                ),

                SizedBox(height: 25),
                _buildSectionTitle('Purchase & Warranty'),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _priceController,
                        'Price',
                        Icons.attach_money,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(child: _buildDatePicker()),
                  ],
                ),
                SizedBox(height: 15),
                _buildTextField(
                  _warrantyMonthsController,
                  'Warranty (Months)',
                  Icons.verified,
                  keyboardType: TextInputType.number,
                  required: false,
                ),
                SizedBox(height: 15),
                _buildTextField(
                  _supplierController,
                  'Supplier / Retailer',
                  Icons.storefront,
                  required: false,
                ),

                SizedBox(height: 25),
                _buildSectionTitle('Condition & Status'),
                SizedBox(height: 10),
                _buildDropdown(
                  'Ownership',
                  _ownershipStatus,
                  _ownershipOptions,
                  (val) => setState(() => _ownershipStatus = val!),
                ),
                SizedBox(height: 15),
                Text(
                  'Condition Score: ${_conditionScore.toInt()}/10',
                  style: TextStyle(color: Colors.white70),
                ),
                Slider(
                  value: _conditionScore,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: GlassTheme.accentColor,
                  onChanged: (val) => setState(() => _conditionScore = val),
                ),

                SizedBox(height: 15),
                _buildTextField(
                  _specsController,
                  'Technical Specs (JSON format)',
                  Icons.code,
                  required: false,
                  maxLines: 3,
                ),
                SizedBox(height: 15),
                _buildTextField(
                  _tagsController,
                  'Tags (comma separated)',
                  Icons.tag,
                  required: false,
                ),

                SizedBox(height: 25),
                _buildSectionTitle('Media & Documentation'),
                SizedBox(height: 10),
                _buildImagePicker(),
                SizedBox(height: 15),
                _buildDocumentsSection(),

                SizedBox(height: 25),
                _buildSectionTitle('Custom Fields'),
                SizedBox(height: 10),
                _buildCustomFieldsEditor(),

                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEdit
                        ? Colors.orangeAccent
                        : GlassTheme.primaryColor,
                    minimumSize: Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 10,
                  ),
                  child: Text(
                    isEdit ? 'Update Gadget' : 'Save Gadget',
                    style: TextStyle(
                      fontSize: 18,
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: GlassTheme.accentColor,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool required = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: GlassTheme.accentColor),
        suffixIcon: label == 'Serial Number'
            ? IconButton(
                icon: Icon(
                  Icons.qr_code_scanner,
                  color: GlassTheme.accentColor,
                ),
                onPressed: () async {
                  final code = await ScannerService.scanCode();
                  if (code != null) controller.text = code;
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: GlassTheme.accentColor),
        ),
      ),
      validator: (value) =>
          (required && (value == null || value.isEmpty)) ? 'Required' : null,
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
        SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Color(0xFF1E293B),
              style: TextStyle(color: Colors.white),
              items: options.map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFolderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Folder / Collection',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            TextButton.icon(
              onPressed: _showAddFolderDialog,
              icon: Icon(Icons.add_box_outlined, size: 14, color: GlassTheme.accentColor),
              label: Text('New Folder', style: TextStyle(color: GlassTheme.accentColor, fontSize: 12)),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFolderId,
              isExpanded: true,
              hint: Text(
                'Select Folder',
                style: TextStyle(color: Colors.white38),
              ),
              dropdownColor: Color(0xFF1E293B),
              style: TextStyle(color: Colors.white),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('None (Root)'),
                ),
                ..._availableFolders.map(
                  (f) => DropdownMenuItem(value: f.id, child: Text(f.name)),
                ),
              ],
              onChanged: (val) => setState(() => _selectedFolderId = val),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddFolderDialog() {
    String folderName = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Folder'),
        backgroundColor: Color(0xFF1E293B),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
        content: TextField(
          autofocus: true,
          onChanged: (v) => folderName = v,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Folder Name',
            labelStyle: TextStyle(color: Colors.white60),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (folderName.isNotEmpty) {
                try {
                  final token = Provider.of<SettingsProvider>(context, listen: false).authToken;
                  final newFolder = await _apiService.createFolder({'name': folderName}, token);
                  await _fetchAvailableFolders();
                  if (mounted) {
                    setState(() => _selectedFolderId = newFolder.id);
                    Navigator.pop(context);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos', style: TextStyle(color: Colors.white60, fontSize: 12)),
        SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._imageUrls.asMap().entries.map(
                (entry) {
                  int index = entry.key;
                  String url = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (url.startsWith('http') || url.startsWith('https') || url.startsWith('blob:'))
                              ? Image.network(url, width: 100, height: 100, fit: BoxFit.cover)
                              : (kIsWeb 
                                  ? Container(
                                      width: 100, 
                                      height: 100, 
                                      color: Colors.white10, 
                                      child: Icon(Icons.image_not_supported, color: Colors.white24)
                                    )
                                  : Image.file(File(url), width: 100, height: 100, fit: BoxFit.cover)),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => setState(() => _imageUrls.removeAt(index)),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              InkWell(
                onTap: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    setState(() => _imageUrls.add(image.path));
                  }
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: GlassTheme.accentColor, size: 28),
                      SizedBox(height: 4),
                      Text('Add Photo', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilePicker(
    String label,
    String? currentUrl,
    Function(String) onPicked,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white60, fontSize: 12)),
        SizedBox(height: 5),
        InkWell(
          onTap: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf', 'jpg', 'png'],
            );
            if (result != null && result.files.single.path != null) {
              onPicked(result.files.single.path!);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Icon(Icons.description, color: GlassTheme.accentColor),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    currentUrl ?? 'No file selected',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documents',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
        SizedBox(height: 10),
        ..._documents.map(
          (doc) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description,
                    color: GlassTheme.accentColor,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc['name'] ?? 'Unnamed Document',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Text(
                          doc['url'] ?? '',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent, size: 18),
                    onPressed: () => setState(() => _documents.remove(doc)),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 10),
        TextButton.icon(
          onPressed: _addDocument,
          icon: Icon(Icons.add, size: 16),
          label: Text('Add Document'),
          style: TextButton.styleFrom(foregroundColor: GlassTheme.accentColor),
        ),
      ],
    );
  }

  void _addDocument() {
    String docName = '';
    String? docPath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Document'),
          backgroundColor: Color(0xFF1E293B),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (v) => docName = v,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Document Name (e.g. Invoice)',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles();
                  if (result != null) {
                    setDialogState(() => docPath = result.files.single.path);
                  }
                },
                icon: Icon(Icons.attach_file),
                label: Text(docPath != null ? 'File Selected' : 'Select File'),
              ),
              if (docPath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    docPath!.split(RegExp(r'[/\\]')).last,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (docName.isNotEmpty && docPath != null) {
                  setState(() {
                    _documents.add({'name': docName, 'url': docPath});
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomFieldsEditor() {
    return Column(
      children: [
        ..._customFields.entries.map(
          (e) => Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${e.key}: ${e.value}',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: Colors.orange),
                  onPressed: () => setState(() => _customFields.remove(e.key)),
                ),
              ],
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _showAddCustomFieldDialog,
          icon: Icon(Icons.add_circle_outline),
          label: Text('Add Custom Field'),
          style: TextButton.styleFrom(foregroundColor: GlassTheme.accentColor),
        ),
      ],
    );
  }

  void _showAddCustomFieldDialog() {
    String key = '';
    String value = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Custom Field'),
        backgroundColor: Color(0xFF1E293B),
        titleTextStyle: TextStyle(color: Colors.white),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (v) => key = v,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Field Name (e.g. Battery Health)',
                labelStyle: TextStyle(color: Colors.white60),
              ),
            ),
            TextField(
              onChanged: (v) => value = v,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Value (e.g. 98%)',
                labelStyle: TextStyle(color: Colors.white60),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (key.isNotEmpty) {
                setState(() => _customFields[key] = value);
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _purchaseDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date != null) setState(() => _purchaseDate = date);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: GlassTheme.accentColor),
            SizedBox(width: 10),
            Text(
              DateFormat('yyyy-MM-dd').format(_purchaseDate),
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        final token = settings.authToken;

        final gadgetData = {
          'name': _nameController.text,
          'category': _category,
          'brand': _brandController.text,
          'model': _modelController.text,
          'storageCapacity': _storageController.text,
          'color': _colorController.text,
          'purchaseStore': _supplierController.text,
          'technicalSpecs': _specsController.text.isNotEmpty ? jsonDecode(_specsController.text) : {},
          'serialNumber': _serialController.text,
          'purchaseDate': DateFormat('yyyy-MM-dd').format(_purchaseDate),
          'purchasePrice': double.parse(_priceController.text),
          'conditionScore': _conditionScore.toInt(),
          'ownershipStatus': _ownershipStatus,
          'room': _roomController.text,
          'folderId': _selectedFolderId,
          'imageUrls': _imageUrls,
          'documents': _documents,
          'customFields': _customFields,
          'tags': _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        };

        if (_warrantyMonthsController.text.isNotEmpty) {
          int months = int.parse(_warrantyMonthsController.text);
          gadgetData['warrantyExpiryDate'] = DateFormat('yyyy-MM-dd').format(
            _purchaseDate.add(Duration(days: (months * 30.44).round())),
          );
        }

        if (widget.gadget != null) {
          await _apiService.updateGadget(widget.gadget!.id, gadgetData, token);
        } else {
          await _apiService.createGadget(gadgetData, token);
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _importCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        await _apiService.importCSV(File(result.files.single.path!), settings.authToken);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import successful')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }
}
