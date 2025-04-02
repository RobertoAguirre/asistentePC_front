import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Obtener la guía general del PIPC
  Future<List<String>> getPIPCGuide() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analysis/guide/pipc'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // El backend devuelve la guía como texto, lo convertimos a lista de secciones
        final guide = data['guide'] as String;
        return guide.split('\n').where((line) => line.trim().isNotEmpty).toList();
      } else {
        throw Exception('Error al cargar la guía');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear un nuevo documento PIPC
  Future<String> createDocument(Map<String, dynamic> document) async {
    try {
      // Convertimos el documento a formato de texto plano
      final content = document['sections'].map((section) => 
        '${section['title']}:\n${section['content']}\n'
      ).join('\n');

      final response = await http.post(
        Uri.parse('$baseUrl/documents'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'content': content}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'] ?? '';
      } else {
        throw Exception('Error al crear el documento');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Analizar un documento PIPC
  Future<Map<String, dynamic>> analyzeDocument(String documentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analysis/document/$documentId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al analizar el documento');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener resultado de un análisis previo
  Future<Map<String, dynamic>> getAnalysisResult(String analysisId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analysis/$analysisId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener el resultado del análisis');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
} 