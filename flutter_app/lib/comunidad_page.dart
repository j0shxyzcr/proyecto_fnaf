import 'package:flutter/material.dart';
import 'api.dart';
import 'estilo.dart';

class ComunidadPage extends StatefulWidget {
  const ComunidadPage({super.key});

  @override
  State<ComunidadPage> createState() => _ComunidadPageState();
}

class _ComunidadPageState extends State<ComunidadPage> {
  late Future<dynamic> publicaciones;

  @override
  void initState() {
    super.initState();
    actualizar();
  }

  void actualizar() {
    setState(() {
      publicaciones = Api.get('/publicaciones');
    });
  }

  Future<void> crearPublicacion() async {
    final titulo = TextEditingController();
    final contenido = TextEditingController();
    final guardado = await showDialog<bool>(
      context: context,
      builder: (ventana) => AlertDialog(
        title: const Text('Nueva publicación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titulo,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Título')),
              TextField(
                  controller: contenido,
                  maxLength: 2000,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(labelText: '¿Qué teoría tienes?')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ventana, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (titulo.text.trim().isEmpty || contenido.text.trim().isEmpty) {
                aviso(ventana, 'Escribe título y contenido');
                return;
              }
              try {
                await Api.post('/publicaciones', {
                  'titulo': titulo.text.trim(),
                  'contenido': contenido.text.trim()
                });
                if (ventana.mounted) Navigator.pop(ventana, true);
              } catch (e) {
                if (ventana.mounted) aviso(ventana, errorTexto(e));
              }
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
    titulo.dispose();
    contenido.dispose();
    if (guardado == true && mounted) actualizar();
  }

  Future<void> reaccionar(int id, String tipo) async {
    try {
      await Api.post('/publicaciones/$id/reaccion', {'tipo': tipo});
      if (mounted) actualizar();
    } catch (e) {
      if (mounted) aviso(context, errorTexto(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Expanded(
                child: Text('COMUNIDAD',
                    style: TextStyle(
                        fontSize: 22,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold))),
            IconButton(
                tooltip: 'Actualizar',
                onPressed: actualizar,
                icon: const Icon(Icons.refresh)),
            ElevatedButton(
                onPressed: crearPublicacion, child: const Text('+ Publicar')),
          ]),
        ),
        Expanded(
            child: FutureBuilder<dynamic>(
          future: publicaciones,
          builder: (context, estado) {
            if (!estado.hasData && !estado.hasError) {
              return const Center(child: CircularProgressIndicator());
            }
            if (estado.hasError) {
              return Center(child: Text(errorTexto(estado.error!)));
            }
            final lista = estado.data as List<dynamic>;
            if (lista.isEmpty) {
              return const Center(
                  child:
                      Text('Todavía no hay publicaciones. ¡Haz la primera!'));
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: lista.length,
              itemBuilder: (context, indice) {
                final item = lista[indice] as Map<String, dynamic>;
                final id = item['id'] as int;
                final miReaccion = item['mi_reaccion']?.toString();
                return caja(
                    hijo: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('👤 ${item['nombre']}',
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(item['titulo'].toString(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 7),
                    Text(item['contenido'].toString()),
                    const SizedBox(height: 12),
                    Text(
                        '${item['reacciones']} reacciones · ${item['comentarios']} comentarios',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12)),
                    Wrap(spacing: 5, children: [
                      PopupMenuButton<String>(
                        onSelected: (tipo) => reaccionar(id, tipo),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'like', child: Text('👍 Me gusta')),
                          PopupMenuItem(
                              value: 'love', child: Text('❤️ Me encanta')),
                          PopupMenuItem(
                              value: 'haha', child: Text('😂 Me divierte')),
                          PopupMenuItem(
                              value: 'wow', child: Text('😮 Me asombra')),
                          PopupMenuItem(
                              value: 'sad', child: Text('😢 Me entristece')),
                          PopupMenuItem(
                              value: 'angry', child: Text('😡 Me enoja')),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 10),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.favorite_border,
                                size: 18, color: Colors.redAccent),
                            const SizedBox(width: 6),
                            Text(miReaccion == null
                                ? 'Reaccionar'
                                : 'Reacción: ${emojis[miReaccion] ?? '👍'}'),
                          ]),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ComentariosPage(
                                    publicacionId: id,
                                    titulo: item['titulo'].toString()),
                              ));
                          if (mounted) actualizar();
                        },
                        icon: const Icon(Icons.comment, size: 18),
                        label: const Text('Comentarios'),
                      ),
                    ]),
                  ],
                ));
              },
            );
          },
        )),
      ],
    );
  }
}

const emojis = {
  'like': '👍',
  'love': '❤️',
  'haha': '😂',
  'wow': '😮',
  'sad': '😢',
  'angry': '😡',
};

class ComentariosPage extends StatefulWidget {
  final int publicacionId;
  final String titulo;
  const ComentariosPage(
      {super.key, required this.publicacionId, required this.titulo});

  @override
  State<ComentariosPage> createState() => _ComentariosPageState();
}

class _ComentariosPageState extends State<ComentariosPage> {
  final texto = TextEditingController();
  late Future<dynamic> comentarios;

  Future<dynamic> obtenerComentarios() =>
      Api.get('/publicaciones/${widget.publicacionId}/comentarios');

  @override
  void initState() {
    super.initState();
    comentarios = obtenerComentarios();
  }

  void cargar() {
    final nuevaCarga = obtenerComentarios();
    setState(() {
      comentarios = nuevaCarga;
    });
  }

  @override
  void dispose() {
    texto.dispose();
    super.dispose();
  }

  Future<void> enviar() async {
    if (texto.text.trim().isEmpty) return;
    try {
      await Api.post('/publicaciones/${widget.publicacionId}/comentarios',
          {'contenido': texto.text.trim()});
      texto.clear();
      if (mounted) cargar();
    } catch (e) {
      if (mounted) aviso(context, errorTexto(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(widget.titulo, overflow: TextOverflow.ellipsis)),
      body: Column(children: [
        Expanded(
            child: FutureBuilder<dynamic>(
          future: comentarios,
          builder: (context, estado) {
            if (!estado.hasData && !estado.hasError) {
              return const Center(child: CircularProgressIndicator());
            }
            if (estado.hasError) {
              return Center(child: Text(errorTexto(estado.error!)));
            }
            final lista = estado.data as List<dynamic>;
            if (lista.isEmpty) {
              return const Center(child: Text('Sin comentarios todavía'));
            }
            return ListView(
                children: lista.map((dato) {
              final item = dato as Map<String, dynamic>;
              return caja(
                  hijo: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(item['nombre'].toString(),
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(item['contenido'].toString()),
                  ]));
            }).toList());
          },
        )),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Expanded(
                child: TextField(
                    controller: texto,
                    maxLength: 500,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        hintText: 'Escribe un comentario...'))),
            IconButton(
                onPressed: enviar,
                icon: const Icon(Icons.send, color: Colors.redAccent)),
          ]),
        ),
      ]),
    );
  }
}
