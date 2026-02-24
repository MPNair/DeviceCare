import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../services/api_service.dart';
import '../services/settings_provider.dart';
import 'package:provider/provider.dart';
import '../themes/glass_theme.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'gadget_detail_screen.dart';

class FolderBrowserScreen extends StatefulWidget {
  @override
  _FolderBrowserScreenState createState() => _FolderBrowserScreenState();
}

class _FolderBrowserScreenState extends State<FolderBrowserScreen> {
  final ApiService _apiService = ApiService();
  List<Folder> _rootFolders = [];
  String _selectedType = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFolders();
  }

  Future<void> _fetchFolders() async {
    try {
      final token = Provider.of<SettingsProvider>(
        context,
        listen: false,
      ).authToken;
      final folders = await _apiService.getFolders(token);
      setState(() {
        // Filter for root folders (parentId is null)
        _rootFolders = folders.where((f) => f.parentId == null).toList();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading folders: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Organization',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.create_new_folder_rounded),
            onPressed: () => _showCreateFolderDialog(),
          ),
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchFolders),
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
        child: Column(
          children: [
            _buildFilterBar(),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _buildFolderList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final types = [
      'all',
      'home',
      'office',
      'warranty',
      'receipts',
      'manuals',
      'brand',
      'category',
      'custom',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: types.map((type) {
          bool isSelected = _selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                type.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedType = type);
              },
              selectedColor: GlassTheme.accentColor,
              backgroundColor: Colors.white12,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFolderList() {
    final filteredFolders = _selectedType == 'all'
        ? _rootFolders
        : _rootFolders.where((f) => f.folderType == _selectedType).toList();

    if (filteredFolders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 60, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'No folders matching "$_selectedType"',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredFolders.length,
      itemBuilder: (context, index) {
        return _buildFolderTile(filteredFolders[index]);
      },
    );
  }

  Widget _buildFolderTile(Folder folder) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassTheme.glassCard(
        context: context,
        child: ExpansionTile(
          leading: Icon(
            _getFolderIcon(folder.folderType),
            color: GlassTheme.accentColor,
          ),
          title: Text(
            folder.name,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${folder.gadgets.length} devices',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white38, size: 18),
            color: Color(0xFF1E293B),
            onSelected: (val) {
              if (val == 'edit') _showEditFolderDialog(folder);
              if (val == 'delete') _showDeleteFolderDialog(folder);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Edit', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          children: [
            ...folder.subFolders.map((sub) => _buildFolderTile(sub)).toList(),
            ...folder.gadgets
                .map(
                  (gadget) => ListTile(
                    leading: Icon(
                      Icons.devices_other,
                      color: Colors.white38,
                      size: 20,
                    ),
                    title: Text(
                      gadget.name,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: Text(
                      gadget.category,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.white24,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GadgetDetailScreen(gadget: gadget),
                        ),
                      );
                    },
                  ),
                )
                .toList(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton.icon(
                onPressed: () => _showCreateFolderDialog(parentId: folder.id),
                icon: Icon(Icons.add, size: 16),
                label: Text('New Subfolder', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: GlassTheme.accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateFolderDialog({String? parentId}) {
    String name = '';
    String type = 'custom';
    bool isCustom = true;

    final folderTypes = [
      'custom',
      'home',
      'office',
      'warranty',
      'receipts',
      'manuals',
      'brand',
      'category',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          backgroundColor: Color(0xFF1E293B),
          title: Text('Create Folder', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: type,
                dropdownColor: Color(0xFF1E293B),
                style: TextStyle(color: Colors.white),
                items: folderTypes
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t[0].toUpperCase() + t.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => dialogSetState(() {
                  type = v!;
                  isCustom = type == 'custom';
                  if (!isCustom)
                    name = type[0].toUpperCase() + type.substring(1);
                }),
              ),
              if (isCustom)
                TextField(
                  onChanged: (v) => name = v,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Folder Name',
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
            ElevatedButton(
              onPressed: () async {
                if (name.isNotEmpty) {
                  try {
                    final token = Provider.of<SettingsProvider>(
                      context,
                      listen: false,
                    ).authToken;
                    await _apiService.createFolder({
                      'name': name,
                      'folderType': type,
                      'parentId': parentId,
                    }, token);
                    Navigator.pop(context);
                    _fetchFolders();
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
      ),
    );
  }

  void _showEditFolderDialog(Folder folder) {
    String name = folder.name;
    String type = folder.folderType;
    bool isCustom = type == 'custom';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          backgroundColor: Color(0xFF1E293B),
          title: Text('Edit Folder', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: type,
                dropdownColor: Color(0xFF1E293B),
                style: TextStyle(color: Colors.white),
                items: ['custom', 'room', 'category', 'brand', 'ownership']
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => dialogSetState(() {
                  type = v!;
                  isCustom = type == 'custom';
                  if (!isCustom) name = type;
                }),
              ),
              if (isCustom)
                TextField(
                  controller: TextEditingController(text: name),
                  onChanged: (v) => name = v,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Folder Name',
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
            ElevatedButton(
              onPressed: () async {
                if (name.isNotEmpty) {
                  try {
                    final token = Provider.of<SettingsProvider>(
                      context,
                      listen: false,
                    ).authToken;
                    await _apiService.updateFolder(folder.id, {
                      'name': name,
                      'folderType': type,
                    }, token);
                    Navigator.pop(context);
                    _fetchFolders();
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteFolderDialog(Folder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E293B),
        title: Text('Delete Folder?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will delete the folder and its subfolders. Gadgets will remain but will be unassigned.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              try {
                final token = Provider.of<SettingsProvider>(
                  context,
                  listen: false,
                ).authToken;
                await _apiService.deleteFolder(folder.id, token);
                Navigator.pop(context);
                _fetchFolders();
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getFolderIcon(String type) {
    switch (type) {
      case 'room':
        return Icons.room_rounded;
      case 'brand':
        return Icons.branding_watermark_rounded;
      case 'category':
        return Icons.category_rounded;
      case 'ownership':
        return Icons.person_pin_circle_rounded;
      default:
        return Icons.folder_rounded;
    }
  }
}
