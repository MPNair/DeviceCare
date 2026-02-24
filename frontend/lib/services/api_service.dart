import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/gadget.dart';
import '../models/folder.dart';
import 'dart:io';
import 'dart:typed_data';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Registration failed');
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
    } else {
      throw Exception('Failed to load analytics');
    }
  }

  Future<Gadget> createGadget(Map<String, dynamic> gadget, String? token) async {
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
      throw Exception('Creation Failed: ${errorData['error'] ?? 'Unknown Error'}');
    }
  }

  Future<Gadget> updateGadget(String id, Map<String, dynamic> gadget, String? token) async {
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

  Future<MaintenanceLog> createMaintenanceLog(String gadgetId, Map<String, dynamic> log, String? token) async {
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
      throw Exception('Log Creation Failed: ${errorData['error'] ?? 'Unknown Error'}');
    }
  }

  // --- Folder Methods ---

  Future<List<Folder>> getFolders(String? token) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    
    final response = await http.get(Uri.parse('$baseUrl/folders'), headers: headers);
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Folder.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load folders: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Folder> createFolder(Map<String, dynamic> folder, String? token) async {
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

  Future<void> updateFolder(String id, Map<String, dynamic> folder, String? token) async {
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
    
    final response = await http.delete(Uri.parse('$baseUrl/folders/$id'), headers: headers);
    if (response.statusCode != 204) {
      throw Exception('Folder deletion failed');
    }
  }

  Future<Uint8List> exportData(String? token) async {
    final headers = {'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    
    final response = await http.get(Uri.parse('$baseUrl/gadgets/export'), headers: headers);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Export failed');
    }
  }

  // --- Import Methods ---

  Future<void> importCSV(File file, String? token) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/gadgets/import'));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    
    var response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('CSV Import Failed');
    }
  }
}
