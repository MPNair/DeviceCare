import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/gadget.dart';
import '../themes/glass_theme.dart';
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';
import '../services/notification_service.dart';
import '../models/folder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (dart.library.html) '../services/api_service_stub.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/local_file_image_io.dart' if (dart.library.html) '../widgets/local_file_image_stub.dart' as local_file_image;

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
  bool _isUploadingImage = false;
  List<Map<String, dynamic>> _documents = [];
  Map<String, dynamic> _customFields = {};

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  ColorScheme get _scheme => Theme.of(context).colorScheme;

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
            colors: _isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [_scheme.surface, _scheme.primaryContainer.withOpacity(0.32)],
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
                  style: TextStyle(color: _scheme.onSurfaceVariant),
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
                      color: _scheme.onPrimary,
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
      style: TextStyle(color: _scheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _scheme.onSurfaceVariant),
        prefixIcon: Icon(icon, color: _scheme.primary),
        filled: true,
        fillColor: _isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: _scheme.outlineVariant.withOpacity(0.65),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: _scheme.primary),
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
          style: TextStyle(color: _scheme.onSurfaceVariant, fontSize: 12),
        ),
        SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: _isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _scheme.outlineVariant.withOpacity(0.65)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: _isDark ? const Color(0xFF1E293B) : Colors.white,
              style: TextStyle(color: _scheme.onSurface),
              items: options.map((String val) {
                return DropdownMenuItem<String>(value: val, child: Text(val));
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
              style: TextStyle(color: _scheme.onSurfaceVariant, fontSize: 12),
            ),
            TextButton.icon(
              onPressed: _showAddFolderDialog,
              icon: Icon(
                Icons.add_box_outlined,
                size: 14,
                color: GlassTheme.accentColor,
              ),
              label: Text(
                'New Folder',
                style: TextStyle(color: GlassTheme.accentColor, fontSize: 12),
              ),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: _isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _scheme.outlineVariant.withOpacity(0.65)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFolderId,
              isExpanded: true,
              hint: Text(
                'Select Folder',
                style: TextStyle(color: _scheme.onSurfaceVariant),
              ),
              dropdownColor: _isDark ? const Color(0xFF1E293B) : Colors.white,
              style: TextStyle(color: _scheme.onSurface),
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
        backgroundColor: _isDark ? const Color(0xFF1E293B) : Colors.white,
        titleTextStyle: TextStyle(color: _scheme.onSurface, fontSize: 18),
        content: TextField(
          autofocus: true,
          onChanged: (v) => folderName = v,
          style: TextStyle(color: _scheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Folder Name',
            labelStyle: TextStyle(color: _scheme.onSurfaceVariant),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _scheme.outlineVariant),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (folderName.isNotEmpty) {
                try {
                  final token = Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).authToken;
                  final newFolder = await _apiService.createFolder({
                    'name': folderName,
                  }, token);
                  await _fetchAvailableFolders();
                  if (mounted) {
                    setState(() => _selectedFolderId = newFolder.id);
                    Navigator.pop(context);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        Text(
          'Photos',
          style: TextStyle(color: _scheme.onSurfaceVariant, fontSize: 12),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._imageUrls.asMap().entries.map((entry) {
                int index = entry.key;
                String url = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            (url.startsWith('http') ||
                                url.startsWith('https') ||
                                url.startsWith('blob:'))
                            ? Image.network(
                                url,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : (url.startsWith('/uploads')
                                  ? Image.network(
                                      '${ApiService.hostUrl}$url',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : local_file_image.buildLocalFileImage(
                                      url,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _imageUrls.removeAt(index)),
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              _isUploadingImage
                  ? Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: _isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _scheme.outlineVariant.withOpacity(0.65),
                        ),
                      ),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          setState(() => _isUploadingImage = true);
                          try {
                            final token = Provider.of<SettingsProvider>(
                              context,
                              listen: false,
                            ).authToken;
                            String uploadedUrl;

                            if (kIsWeb) {
                              final bytes = await image.readAsBytes();
                              uploadedUrl = await _apiService.uploadFileBytes(
                                bytes,
                                image.name,
                                token,
                              );
                            } else {
                              final urls = await _apiService.uploadFiles([
                                image.path,
                              ], token);
                              uploadedUrl = urls.first;
                            }

                            if (mounted) {
                              setState(() {
                                _imageUrls.add(uploadedUrl);
                                _isUploadingImage = false;
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => _isUploadingImage = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Image upload failed: $e'),
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: _isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _scheme.outlineVariant.withOpacity(0.65),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              color: GlassTheme.accentColor,
                              size: 28,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                color: _scheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
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
              color: _isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _scheme.outlineVariant.withOpacity(0.65),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.description, color: GlassTheme.accentColor),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    currentUrl ?? 'No file selected',
                    style: TextStyle(color: _scheme.onSurfaceVariant),
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
          style: TextStyle(color: _scheme.onSurfaceVariant, fontSize: 12),
        ),
        SizedBox(height: 10),
        ..._documents.map(
          (doc) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _scheme.outlineVariant.withOpacity(0.65),
                ),
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
                          style: TextStyle(
                            color: _scheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          doc['url'] ?? '',
                          style: TextStyle(
                            color: _scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
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
    Uint8List? docBytes;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Document'),
          backgroundColor: _isDark ? const Color(0xFF1E293B) : Colors.white,
          titleTextStyle: TextStyle(color: _scheme.onSurface, fontSize: 18),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (v) => docName = v,
                style: TextStyle(color: _scheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Document Name (e.g. Invoice)',
                  labelStyle: TextStyle(color: _scheme.onSurfaceVariant),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: isUploading
                    ? null
                    : () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(withData: kIsWeb);
                        if (result != null) {
                          setDialogState(() {
                            if (kIsWeb) {
                              docBytes = result.files.single.bytes;
                              docPath = result.files.single.name;
                            } else {
                              docPath = result.files.single.path;
                            }
                          });
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
                    style: TextStyle(
                      color: _scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (isUploading)
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: (isUploading || docPath == null || docName.isEmpty)
                  ? null
                  : () async {
                      setDialogState(() => isUploading = true);
                      try {
                        final token = Provider.of<SettingsProvider>(
                          context,
                          listen: false,
                        ).authToken;
                        String uploadedUrl;
                        if (kIsWeb && docBytes != null) {
                          uploadedUrl = await _apiService.uploadFileBytes(
                            docBytes!,
                            docPath!,
                            token,
                          );
                        } else {
                          final urls = await _apiService.uploadFiles([
                            docPath!,
                          ], token);
                          uploadedUrl = urls.first;
                        }

                        setState(() {
                          _documents.add({'name': docName, 'url': uploadedUrl});
                        });
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        setDialogState(() => isUploading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Upload failed: $e')),
                        );
                      }
                    },
              child: Text('Upload & Add'),
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
              color: _isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _scheme.outlineVariant.withOpacity(0.65),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${e.key}: ${e.value}',
                    style: TextStyle(color: _scheme.onSurface),
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
        backgroundColor: _isDark ? const Color(0xFF1E293B) : Colors.white,
        titleTextStyle: TextStyle(color: _scheme.onSurface),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (v) => key = v,
              style: TextStyle(color: _scheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Field Name (e.g. Battery Health)',
                labelStyle: TextStyle(color: _scheme.onSurfaceVariant),
              ),
            ),
            TextField(
              onChanged: (v) => value = v,
              style: TextStyle(color: _scheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Value (e.g. 98%)',
                labelStyle: TextStyle(color: _scheme.onSurfaceVariant),
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
          color: _isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _scheme.outlineVariant.withOpacity(0.65)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: GlassTheme.accentColor),
            SizedBox(width: 10),
            Text(
              DateFormat('yyyy-MM-dd').format(_purchaseDate),
              style: TextStyle(color: _scheme.onSurface),
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

        List<String> localImages = _imageUrls
            .where(
              (url) => !url.startsWith('http') && !url.startsWith('/uploads'),
            )
            .toList();
        List<String> finalImageUrls = _imageUrls
            .where(
              (url) => url.startsWith('http') || url.startsWith('/uploads'),
            )
            .toList();

        if (localImages.isNotEmpty) {
          final uploadedUrls = await _apiService.uploadFiles(
            localImages,
            token,
          );
          finalImageUrls.addAll(uploadedUrls);
        }

        List<Map<String, String>> finalDocuments = [];
        List<String> localDocPaths = [];
        List<int> localDocIndices = [];

        for (int i = 0; i < _documents.length; i++) {
          final doc = _documents[i];
          final url = doc['url'] ?? '';
          if (!url.startsWith('http') && !url.startsWith('/uploads')) {
            localDocPaths.add(url);
            localDocIndices.add(i);
          } else {
            finalDocuments.add({'name': doc['name']!, 'url': url});
          }
        }

        if (localDocPaths.isNotEmpty) {
          final uploadedUrls = await _apiService.uploadFiles(
            localDocPaths,
            token,
          );
          for (int i = 0; i < uploadedUrls.length; i++) {
            final originalDoc = _documents[localDocIndices[i]];
            finalDocuments.add({
              'name': originalDoc['name']!,
              'url': uploadedUrls[i],
            });
          }
        }

        final gadgetData = {
          'name': _nameController.text,
          'category': _category,
          'brand': _brandController.text,
          'model': _modelController.text,
          'storageCapacity': _storageController.text,
          'color': _colorController.text,
          'purchaseStore': _supplierController.text,
          'technicalSpecs': _specsController.text.isNotEmpty
              ? jsonDecode(_specsController.text)
              : {},
          'serialNumber': _serialController.text,
          'purchaseDate': DateFormat('yyyy-MM-dd').format(_purchaseDate),
          'purchasePrice': double.parse(_priceController.text),
          'conditionScore': _conditionScore.toInt(),
          'ownershipStatus': _ownershipStatus,
          'room': _roomController.text,
          'folderId': _selectedFolderId,
          'imageUrls': finalImageUrls,
          'documents': finalDocuments,
          'customFields': _customFields,
          'tags': _tagsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
        };

        if (_warrantyMonthsController.text.isNotEmpty) {
          int months = int.parse(_warrantyMonthsController.text);
          gadgetData['warrantyExpiryDate'] = DateFormat(
            'yyyy-MM-dd',
          ).format(_purchaseDate.add(Duration(days: (months * 30.44).round())));
        }

        if (widget.gadget != null) {
          await _apiService.updateGadget(widget.gadget!.id, gadgetData, token);
        } else {
          await _apiService.createGadget(gadgetData, token);
        }

        await NotificationService.syncSchedulesFromApi(context);

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
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

      if (result == null || result.files.isEmpty) return;

      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final file = result.files.single;

      if (kIsWeb && file.bytes != null) {
        await _apiService.importCSVFromBytes(file.bytes!, settings.authToken);
      } else if (!kIsWeb && file.path != null) {
        await _apiService.importCSV(File(file.path!), settings.authToken);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read file')),
          );
        }
        return;
      }
      await NotificationService.syncSchedulesFromApi(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import successful')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
