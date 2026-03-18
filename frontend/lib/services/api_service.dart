import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/gadget.dart';
import '../models/folder.dart';
import 'dart:typed_data';
import 'dart:io' if (dart.library.html) 'api_service_stub.dart';

class ApiService {
  /// User-friendly message when backend is not running.
  static const String _connectionErrorMsg =
      'Backend server is not reachable. Start it from the project root: cd backend && npm start';

  static bool _isConnectionError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('failed to fetch') ||
        s.contains('clientexception') ||
        s.contains('connection refused') ||
        s.contains('connection reset') ||
        s.contains('socketexception');
  }

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
  }

  static String get hostUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    } else {
      return 'http://localhost:3000';
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Login failed');
    } catch (e) {
      if (_isConnectionError(e)) throw Exception(_connectionErrorMsg);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'email': email, 'password': password}),
      );
      if (response.statusCode == 201) {
        return json.decode(response.body);
      }
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Registration failed');
    } catch (e) {
      if (_isConnectionError(e)) throw Exception(_connectionErrorMsg);
      rethrow;
    }
  }

  Future<List<Gadget>> getGadgets(String? token) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/gadgets'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Gadget.fromJson(data)).toList();
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      if (_isConnectionError(e)) throw Exception(_connectionErrorMsg);
      throw Exception('Connection failed: $e');
    }
  }

  Future<Gadget> getGadgetById(String id, String? token) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(
      Uri.parse('$baseUrl/gadgets/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Gadget.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load gadget');
    }
  }

  Future<Map<String, dynamic>> getAnalytics(String? token) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/dashboard'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load analytics');
    } catch (e) {
      if (_isConnectionError(e)) throw Exception(_connectionErrorMsg);
      rethrow;
    }
  }

  Future<Gadget> createGadget(
    Map<String, dynamic> gadget,
    String? token,
  ) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.post(
      Uri.parse('$baseUrl/gadgets'),
      headers: headers,
      body: json.encode(gadget),
    );
    if (response.statusCode == 201) {
      return Gadget.fromJson(json.decode(response.body));
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
        'Creation Failed: ${errorData['error'] ?? 'Unknown Error'}',
      );
    }
  }

  Future<Gadget> updateGadget(
    String id,
    Map<String, dynamic> gadget,
    String? token,
  ) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.put(
      Uri.parse('$baseUrl/gadgets/$id'),
      headers: headers,
      body: json.encode(gadget),
    );
    if (response.statusCode == 200) {
      return Gadget.fromJson(json.decode(response.body));
    } else {
      throw Exception('Update Failed: ${response.statusCode}');
    }
  }

  Future<void> deleteGadget(String id, String? token) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/gadgets/$id'),
      headers: headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Delete Failed');
    }
  }

  Future<MaintenanceLog> createMaintenanceLog(
    String gadgetId,
    Map<String, dynamic> log,
    String? token,
  ) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.post(
      Uri.parse('$baseUrl/logs/$gadgetId/logs'),
      headers: headers,
      body: json.encode(log),
    );

    if (response.statusCode == 201) {
      return MaintenanceLog.fromJson(json.decode(response.body));
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
        'Log Creation Failed: ${errorData['error'] ?? 'Unknown Error'}',
      );
    }
  }

  // --- Folder Methods ---

  Future<List<Folder>> getFolders(String? token) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await http.get(
      Uri.parse('$baseUrl/folders'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Folder.fromJson(data)).toList();
    } else {
      throw Exception(
        'Failed to load folders: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<Folder> createFolder(
    Map<String, dynamic> folder,
    String? token,
  ) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await http.post(
      Uri.parse('$baseUrl/folders'),
      headers: headers,
      body: json.encode(folder),
    );
    if (response.statusCode == 201) {
      return Folder.fromJson(json.decode(response.body));
    } else {
      throw Exception('Folder creation failed');
    }
  }

  Future<void> updateFolder(
    String id,
    Map<String, dynamic> folder,
    String? token,
  ) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await http.put(
      Uri.parse('$baseUrl/folders/$id'),
      headers: headers,
      body: json.encode(folder),
    );
    if (response.statusCode != 200) {
      throw Exception('Folder update failed');
    }
  }

  Future<void> deleteFolder(String id, String? token) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await http.delete(
      Uri.parse('$baseUrl/folders/$id'),
      headers: headers,
    );
    if (response.statusCode != 204) {
      throw Exception('Folder deletion failed');
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String? token,
  ) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.put(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: headers,
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      if (response.statusCode == 200) return;
      try {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Password change failed');
      } on FormatException {
        throw Exception(
          'Server error (status ${response.statusCode}). Make sure the backend is running and restarted.',
        );
      }
    } catch (e) {
      if (_isConnectionError(e)) throw Exception(_connectionErrorMsg);
      rethrow;
    }
  }

  Future<Uint8List> exportData(String? token) async {
    final headers = {
      'Accept':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await http.get(
      Uri.parse('$baseUrl/gadgets/export'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Export failed');
    }
  }

  // --- Import Methods ---

  /// Import CSV from bytes. Use this on web where File is not available.
  Future<void> importCSVFromBytes(Uint8List bytes, String? token) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/gadgets/import'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: 'import.csv'),
    );
    var response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('CSV Import Failed');
    }
  }

  Future<void> importCSV(File file, String? token) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/gadgets/import'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: 'import.csv'),
      );
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    }
    var response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('CSV Import Failed');
    }
  }

  // --- File Upload Methods ---

  Future<List<String>> uploadFiles(
    List<String> filePaths,
    String? token,
  ) async {
    if (filePaths.isEmpty) return [];

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    for (var path in filePaths) {
      if (kIsWeb) {
        // Handle web blob URLs by fetching the bytes first
        final response = await http.get(Uri.parse(path));
        final bytes = response.bodyBytes;
        final filename =
            path.split('/').last.split('?').first + '.jpg'; // Fallback name
        request.files.add(
          http.MultipartFile.fromBytes('files', bytes, filename: filename),
        );
      } else {
        request.files.add(await http.MultipartFile.fromPath('files', path));
      }
    }

    var response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final Map<String, dynamic> jsonResponse = json.decode(respStr);
      return List<String>.from(jsonResponse['urls']);
    } else {
      throw Exception(
        'Failed to upload files. Status Code: ${response.statusCode}',
      );
    }
  }

  Future<String> uploadFileBytes(
    Uint8List bytes,
    String filename,
    String? token,
  ) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      http.MultipartFile.fromBytes('files', bytes, filename: filename),
    );

    var response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final Map<String, dynamic> jsonResponse = json.decode(respStr);
      final List<String> urls = List<String>.from(jsonResponse['urls']);
      if (urls.isNotEmpty) return urls.first;
      throw Exception('Upload succeeded but no URL returned.');
    } else {
      throw Exception(
        'Failed to upload file bytes. Status Code: ${response.statusCode}',
      );
    }
  }
}
