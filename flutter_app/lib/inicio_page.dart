import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'estilo.dart';

class InicioPage extends StatefulWidget {
  final String nombre;
  const InicioPage({super.key, required this.nombre});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  late Future<dynamic> videos;

  @override
  void initState() {
    super.initState();
    videos = Api.get('/videos');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        caja(
            hijo: Column(
          children: [
            const Icon(Icons.flashlight_off, size: 55, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text('FNAF BLOG',
                style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent)),
            const Text('historias y lore q el creador ni siquiera sabia q existian',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Bienvenido, ${widget.nombre}'),
            const SizedBox(height: 12),
            const Text(
                'un vlog bien chido para fans de Five Nights at Freddy\'s. asi bien rojito como el fnaf 4',
                textAlign: TextAlign.center),
          ],
    JUV    )),
        const SizedBox(height: 15),
        const Text('NUESTRO VLOG',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent)),
        const SizedBox(height: 8),
        FutureBuilder<dynamic>(
          future: videos,
          builder: (context, estado) {
            if (!estado.hasData && !estado.hasError) {
              return const Center(child: CircularProgressIndicator());
            }
            if (estado.hasError) return Text(errorTexto(estado.error!));
            final lista = estado.data as List<dynamic>;
            if (lista.isEmpty) {
              return const Text('Próximamente subiremos nuestros videos.');
            }
            return Column(
                children: lista.map((dato) {
              final item = dato as Map<String, dynamic>;
              final url = item['url'] as String?;
              return caja(
                  hijo: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['titulo'].toString(),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(item['descripcion'].toString()),
                  const SizedBox(height: 8),
                  url == null || url.isEmpty
                      ? const Text('Video próximamente',
                          style: TextStyle(color: Colors.redAccent))
                      : TextButton.icon(
                          onPressed: () async {
                            final enlace = Uri.tryParse(url);
                            if (enlace != null &&
                                enlace.scheme == 'https' &&
                                (enlace.host == 'youtube.com' ||
                                    enlace.host == 'www.youtube.com' ||
                                    enlace.host == 'youtu.be')) {
                              if (!await launchUrl(enlace,
                                      mode: LaunchMode.externalApplication) &&
                                  context.mounted) {
                                aviso(context, 'No se pudo abrir el video');
                              }
                            } else {
                              aviso(context, 'El enlace de video no es válido');
                            }
                          },
                          icon: const Icon(Icons.play_circle),
                          label: const Text('Ver video'),
                        ),
                ],
              ));
            }).toList());
          },
        ),
        const SizedBox(height: 15),
        const Text('fan blog, no nos demanden porfa.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center),
      ],
    );
  }
}
