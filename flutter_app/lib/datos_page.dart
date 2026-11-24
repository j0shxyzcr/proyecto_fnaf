import 'package:flutter/material.dart';
import 'api.dart';
import 'estilo.dart';
class DatosPage extends StatefulWidget {
  final String titulo;
  final String ruta;
  const DatosPage({super.key, required this.titulo, required this.ruta});

  @override
  State<DatosPage> createState() => _DatosPageState();
}

class _DatosPageState extends State<DatosPage> {
  late Future<dynamic> datos;

  @override
  void initState() {
    super.initState();
    datos = Api.get(widget.ruta);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: datos,
      builder: (context, estado) {
        if (!estado.hasData && !estado.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (estado.hasError) {
          return Center(child: Text(errorTexto(estado.error!)));
        }
        final lista = estado.data as List<dynamic>;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(widget.titulo,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent)),
            const SizedBox(height: 10),
            ...lista.map((dato) {
              final item = dato as Map<String, dynamic>;
              return caja(
                  hijo: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['titulo'].toString(),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent)),
                  if (item['anio'] != null)
                    Text('Año: ${item['anio']}',
                        style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text((item['contenido'] ?? item['descripcion']).toString()),
                ],
              ));
            }),
          ],
        );
      },
    );
  }
}
