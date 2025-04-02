import 'package:flutter/material.dart';
import '../models/pipc_document.dart';
import '../services/api_service.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _document = PIPCDocument();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _apiService = ApiService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDocument();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initDocument() async {
    setState(() => _isLoading = true);
    
    try {
      // Intentar cargar borrador guardado
      final hasDraft = await _document.loadDraft();
      if (!hasDraft) {
        // Si no hay borrador, cargar guía nueva
        _document.sections = await _apiService.getPIPCGuide();
        _document.contents = List.filled(_document.sections.length, '');
      }
      
      // Actualizar el controlador con el contenido actual
      _controller.text = _document.currentContent;
    } catch (e) {
      debugPrint('Error loading document: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDocument() async {
    try {
      final documentId = await _apiService.createDocument(_document.toJson());
      if (documentId.isNotEmpty) {
        // Limpiar borrador después de guardar exitosamente
        await _document.clearDraft();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Documento guardado exitosamente')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar el documento'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text('Editor PIPC'),
        actions: [
          // Mostrar progreso
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Progreso: ${(_document.getProgress() * 100).toInt()}%',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDocument,
          ),
        ],
      ),
      body: Row(
        children: [
          // Panel de navegación
          Container(
            width: 250,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: ListView.builder(
              itemCount: _document.totalSections,
              itemBuilder: (context, index) {
                final hasContent = _document.contents[index].trim().isNotEmpty;
                return ListTile(
                  title: Text(_document.sections[index]),
                  selected: _document.currentSection == index,
                  trailing: hasContent ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    setState(() {
                      _document.setCurrentSection(index);
                      _controller.text = _document.currentContent;
                    });
                  },
                );
              },
            ),
          ),
          // Editor
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _document.sections[_document.currentSection],
                    style: Theme.of(context).textTheme.headlineSmall,
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
                        hintText: 'Escribe el contenido de la sección...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() => _document.updateContent(value));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 