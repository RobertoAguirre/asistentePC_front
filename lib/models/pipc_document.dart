import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PIPCDocument {
  List<String> sections = [];
  List<String> contents = [];
  int currentSection = 0;
  static const String _storageKey = 'pipc_document_draft';

  int get totalSections => sections.length;
  
  String get currentContent => contents.isNotEmpty ? contents[currentSection] : '';

  void setCurrentSection(int index) {
    if (index >= 0 && index < sections.length) {
      currentSection = index;
    }
  }

  void updateContent(String content) {
    if (currentSection >= 0 && currentSection < contents.length) {
      contents[currentSection] = content;
      _saveDraft(); // Guardar automáticamente al actualizar contenido
    }
  }

  double getProgress() {
    if (contents.isEmpty) return 0;
    return contents.where((content) => content.trim().isNotEmpty).length / contents.length;
  }

  // Guardar borrador localmente
  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'sections': sections,
      'contents': contents,
      'currentSection': currentSection,
    };
    await prefs.setString(_storageKey, json.encode(data));
  }

  // Cargar borrador guardado
  Future<bool> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_storageKey);
    if (savedData != null) {
      try {
        final data = json.decode(savedData);
        sections = List<String>.from(data['sections']);
        contents = List<String>.from(data['contents']);
        currentSection = data['currentSection'];
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  // Limpiar borrador
  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Map<String, dynamic> toJson() {
    return {
      'sections': sections.asMap().entries.map((entry) => {
        'title': entry.value,
        'content': contents[entry.key],
      }).toList(),
    };
  }
} 