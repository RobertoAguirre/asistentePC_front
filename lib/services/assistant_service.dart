import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class AssistantService {
  // URL por defecto del backend
  final String baseUrl = 'http://localhost:3000';

  Future<String> getAssistanceForSection(String sectionTitle, String currentContent) async {
    final endpoint = '$baseUrl/api/analysis/pipc-assistant';
    developer.log('Llamando al endpoint: $endpoint');
    developer.log('Datos enviados: section=$sectionTitle, userInput=$currentContent');

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'section': sectionTitle,
          'userInput': currentContent,
        }),
      );

      developer.log('Código de respuesta: ${response.statusCode}');
      developer.log('Respuesta del servidor: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] as String;
      } else if (response.statusCode == 400) {
        return 'Por favor, selecciona una sección para recibir ayuda.';
      } else {
        return 'Error al conectar con el asistente. Status: ${response.statusCode}';
      }
    } catch (e) {
      developer.log('Error en la llamada: $e');
      return 'No se pudo conectar con el servidor. Error: $e';
    }
  }

  Future<String> validateCurrentSection(String sectionTitle, String content) async {
    final endpoint = '$baseUrl/api/analysis/validate-section';
    developer.log('Llamando al endpoint de validación: $endpoint');
    
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'section': sectionTitle,
          'content': content,
        }),
      );

      developer.log('Código de respuesta validación: ${response.statusCode}');
      developer.log('Respuesta validación: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] as String;
      } else {
        return 'Error al validar la sección. Status: ${response.statusCode}';
      }
    } catch (e) {
      developer.log('Error en validación: $e');
      return 'No se pudo conectar con el servidor de validación. Error: $e';
    }
  }
} 