import 'package:flutter/material.dart';
import '../models/pipc_document.dart';
import '../services/api_service.dart';
import '../services/assistant_service.dart';
import 'dart:async';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final PIPCDocument _document = PIPCDocument();
  final AssistantService _assistant = AssistantService();
  bool _isLoading = true;
  bool _showAssistant = true;
  String _assistantResponse = 'Cargando asistente...';
  bool _isAssistantLoading = false;
  Timer? _debounceTimer;

  // Ejemplos de ayuda para cada sección
  final Map<String, String> _assistantHelp = {
    'Aquí tienes una guía paso a paso detallada': 'Esta es la introducción general del documento. No necesitas modificar esta sección.',
    'I. Estructura básica del PIPC': 'En esta sección debes describir la estructura general de tu PIPC. Incluye los elementos principales como objetivos, alcance y responsabilidades.',
    'Portada': 'La portada debe incluir:\n\n• Título del documento\n• Nombre de tu establecimiento\n• Dirección completa\n• Fecha de elaboración\n• Responsable del PIPC',
    'Título: "Programa Interno de Protección': 'Escribe el título completo: "Programa Interno de Protección Civil para [Nombre de tu establecimiento]"',
  };

  String get _currentHelp {
    if (_document.sections.isEmpty) return '';
    return _assistantHelp[_document.sections[_document.currentSection]] ?? 
           'Escribe el contenido correspondiente a esta sección según los requisitos normativos vigentes.';
  }

  @override
  void initState() {
    super.initState();
    _initDocument();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initDocument() async {
    setState(() => _isLoading = true);
    
    final hasDraft = await _document.loadDraft();
    if (!hasDraft) {
      final guide = await ApiService().getPIPCGuide();
      _document.sections = guide;
      _document.contents = List.filled(guide.length, '');
    }
    
    _controller.text = _document.currentContent;
    _updateAssistantHelp();
    setState(() => _isLoading = false);
  }

  Future<void> _updateAssistantHelp([String? userInput]) async {
    if (!_showAssistant) return;

    setState(() => _isAssistantLoading = true);
    try {
      final assistance = await _assistant.getAssistanceForSection(
        _document.sections[_document.currentSection],
        userInput ?? _controller.text,
      );
      if (mounted) {
        setState(() => _assistantResponse = assistance);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _assistantResponse = 'Error al cargar el asistente. Por favor, intenta de nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() => _isAssistantLoading = false);
      }
    }
  }

  void _onTextChanged(String value) {
    _document.updateContent(value);
    setState(() {});

    // Debounce para no hacer demasiadas llamadas al asistente
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      if (value.toLowerCase().contains('como hago esta seccion')) {
        _updateAssistantHelp(value);
      }
    });
  }

  Future<void> _validateCurrentSection() async {
    setState(() => _isAssistantLoading = true);
    try {
      final validation = await _assistant.validateCurrentSection(
        _document.sections[_document.currentSection],
        _controller.text,
      );
      if (mounted) {
        setState(() => _assistantResponse = validation);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _assistantResponse = 'Error al validar la sección. Por favor, intenta de nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() => _isAssistantLoading = false);
      }
    }
  }

  Future<void> _saveDocument() async {
    try {
      await ApiService().createDocument(_document.toJson());
      await _document.clearDraft();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento guardado con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar el documento')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de PIPC'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Progreso: ${(_document.getProgress() * 100).toInt()}%',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          IconButton(
            icon: Icon(_showAssistant ? Icons.help : Icons.help_outline),
            onPressed: () {
              setState(() {
                _showAssistant = !_showAssistant;
                if (_showAssistant) _updateAssistantHelp();
              });
            },
            tooltip: 'Mostrar/Ocultar Asistente',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDocument,
          ),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                right: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: ListView.builder(
              itemCount: _document.sections.length,
              itemBuilder: (context, index) {
                final isComplete = _document.contents[index].trim().isNotEmpty;
                return ListTile(
                  title: Text(
                    _document.sections[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                  selected: index == _document.currentSection,
                  selectedTileColor: Colors.white.withOpacity(0.1),
                  trailing: isComplete
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.circle_outlined, color: Colors.white70),
                  onTap: () {
                    setState(() {
                      _document.setCurrentSection(index);
                      _controller.text = _document.currentContent;
                      _updateAssistantHelp();
                    });
                  },
                );
              },
            ),
          ),
          Expanded(
            flex: _showAssistant ? 2 : 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _document.sections[_document.currentSection],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: 'Escribe el contenido de la sección o pregunta "¿como hago esta seccion?"...',
                        border: OutlineInputBorder(),
                        fillColor: Color(0xFFF5F5F5),
                        filled: true,
                      ),
                      style: const TextStyle(color: Colors.black87),
                      onChanged: _onTextChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showAssistant)
            Container(
              width: 300,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.smart_toy, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Asistente PIPC',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isAssistantLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            child: Text(
                              _assistantResponse,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _validateCurrentSection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check),
                        SizedBox(width: 8),
                        Text('Validar sección'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 