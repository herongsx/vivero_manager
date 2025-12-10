
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyR5bRDJ0g7TxUEbOPt3Zr5KYP7Xf6c8A",
        authDomain: "vivero-manager-5c764.firebaseapp.com",
        projectId: "vivero-manager-5c764",
        storageBucket: "vivero-manager-5c764.firebasestorage.app",
        messagingSenderId: "857707682398",
        appId: "1:857707682398:web:fbbd4841426e2af2e2f2cf",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const ViveroApp());
}

class ViveroApp extends StatelessWidget {
  const ViveroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vivero Manager',
      theme: ThemeData(primarySwatch: Colors.green),
      debugShowCheckedModeBanner: false,
      home: const PlantasPage(),
    );
  }
}

class PlantasPage extends StatelessWidget {
  const PlantasPage({super.key});

  CollectionReference get _plantasRef =>
      FirebaseFirestore.instance.collection('plantas');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plantas del Vivero')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _plantasRef.orderBy('nombre').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar datos'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No hay plantas registradas'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final nombre = data['nombre'] ?? 'Sin nombre';
              final ubicacion = data['ubicacion'] ?? 'Sin ubicación';
              final humedad = data['humedad']?.toString() ?? '-';
              final nota = data['nota'] ?? '';

              return ListTile(
                title: Text(nombre),
                subtitle: Text(
                  'Ubicación: $ubicacion\nHumedad: $humedad%\n$nota',
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _mostrarFormularioPlanta(
                          context,
                          docId: doc.id,
                          datos: data,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await _plantasRef.doc(doc.id).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Planta eliminada')),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _mostrarFormularioPlanta(context);
        },
      ),
    );
  }

  void _mostrarFormularioPlanta(
      BuildContext context, {
        String? docId,
        Map<String, dynamic>? datos,
      }) {
    final nombreController =
    TextEditingController(text: datos != null ? datos['nombre'] ?? '' : '');
    final ubicacionController = TextEditingController(
        text: datos != null ? datos['ubicacion'] ?? '' : '');
    final humedadController = TextEditingController(
        text: datos != null ? (datos['humedad']?.toString() ?? '') : '');
    final notaController =
    TextEditingController(text: datos != null ? datos['nota'] ?? '' : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(docId == null ? 'Agregar planta' : 'Editar planta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: ubicacionController,
                  decoration: const InputDecoration(labelText: 'Ubicación'),
                ),
                TextField(
                  controller: humedadController,
                  decoration:
                  const InputDecoration(labelText: 'Humedad (%)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: notaController,
                  decoration: const InputDecoration(labelText: 'Nota'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(docId == null ? 'Guardar' : 'Actualizar'),
              onPressed: () async {
                final nombre = nombreController.text.trim();
                final ubicacion = ubicacionController.text.trim();
                final humedadText = humedadController.text.trim();
                final nota = notaController.text.trim();

                final humedad =
                humedadText.isNotEmpty ? int.tryParse(humedadText) : null;

                final data = <String, dynamic>{
                  'nombre': nombre,
                  'ubicacion': ubicacion,
                  'humedad': humedad,
                  'nota': nota,
                  'creadoEn': FieldValue.serverTimestamp(),
                };

                try {
                  if (docId == null) {
                    await _plantasRef.add(data);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Planta agregada')),
                    );
                  } else {
                    await _plantasRef.doc(docId).update(data);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Planta actualizada')),
                    );
                  }

                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
