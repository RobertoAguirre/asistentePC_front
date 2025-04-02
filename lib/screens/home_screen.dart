import 'package:flutter/material.dart';
import '../models/pipc_document.dart';
import 'editor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PIPC Editor'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bienvenido al Editor PIPC',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditorScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Crear Nuevo Documento'),
            ),
          ],
        ),
      ),
    );
  }
} 