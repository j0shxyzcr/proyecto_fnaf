import 'package:flutter/material.dart';

import 'api.dart';
import 'estilo.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    const recursos = [
      _RecursoAdmin(
        ruta: 'lore',
        nombre: 'artículo de lore',
        icono: Icons.menu_book,
        campos: [
          _CampoAdmin('Título', 'titulo'),
          _CampoAdmin('Contenido', 'contenido', multilinea: true),
        ],
      ),
      _RecursoAdmin(
        ruta: 'juegos',
        nombre: 'juego',
        icono: Icons.videogame_asset,
        campos: [
          _CampoAdmin('Título', 'titulo'),
          _CampoAdmin('Año', 'anio', numerico: true),
          _CampoAdmin('Descripción', 'descripcion', multilinea: true),
        ],
      ),
      _RecursoAdmin(
        ruta: 'videos',
        nombre: 'video',
        icono: Icons.ondemand_video,
        campos: [
          _CampoAdmin('Título', 'titulo'),
          _CampoAdmin('Descripción', 'descripcion', multilinea: true),
          _CampoAdmin('Enlace (opcional)', 'url', opcional: true),
        ],
      ),
      _RecursoAdmin(
        ruta: 'productos',
        nombre: 'producto',
        icono: Icons.toys,
        campos: [
          _CampoAdmin('Nombre', 'nombre'),
          _CampoAdmin('Descripción', 'descripcion', multilinea: true),
          _CampoAdmin('Precio', 'precio', numerico: true),
          _CampoAdmin('Existencias', 'stock', numerico: true),
        ],
      ),
    ];
    final tabs = <Tab>[
      const Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
      ...recursos.map((recurso) => Tab(
            icon: Icon(recurso.icono),
            text: recurso.ruta.toUpperCase(),
          )),
      const Tab(icon: Icon(Icons.forum), text: 'Publicaciones'),
      const Tab(icon: Icon(Icons.people), text: 'Usuarios'),
      const Tab(icon: Icon(Icons.receipt_long), text: 'Pedidos'),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CENTRO DE CONTROL'),
          bottom: TabBar(
            isScrollable: true,
            tabs: tabs,
          ),
        ),
        body: TabBarView(
          children: [
            const _ResumenAdminPage(),
            ...recursos.map((recurso) => _CatalogoAdminPage(recurso: recurso)),
            const _ModeracionAdminPage(),
            const _UsuariosAdminPage(),
            _ListaAdminPage(
              ruta: '/admin/pedidos',
              titulo: 'Pedidos de prueba',
              icono: Icons.receipt_long,
              encabezado: (item) => 'Pedido #${item['id']} · ${item['nombre']}',
              detalle: (item) =>
                  '${item['articulos']} artículos · Estado: ${item['estado']} · ${item['fecha']}',
              monto: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenAdminPage extends StatefulWidget {
  const _ResumenAdminPage();

  @override
  State<_ResumenAdminPage> createState() => _ResumenAdminPageState();
}

class _ResumenAdminPageState extends State<_ResumenAdminPage> {
  late Future<dynamic> resumen;

  @override
  void initState() {
    super.initState();
    resumen = Api.get('/admin/resumen');
  }

  void actualizar() => setState(() => resumen = Api.get('/admin/resumen'));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: resumen,
      builder: (context, estado) {
        if (!estado.hasData && !estado.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (estado.hasError) {
          return _ErrorAdmin(
            mensaje: errorTexto(estado.error!),
            reintentar: actualizar,
          );
        }
        final datos = estado.data as Map<String, dynamic>;
        const indicadores = [
          ('Usuarios', 'usuarios', Icons.people),
          ('Publicaciones', 'publicaciones', Icons.forum),
          ('Comentarios', 'comentarios', Icons.comment),
          ('Pedidos de prueba', 'pedidos', Icons.receipt_long),
          ('Productos', 'productos', Icons.toys),
          ('Stock bajo (< 5)', 'stock_bajo', Icons.warning_amber),
        ];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Vista general',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: actualizar,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const Text(
              'Administra el contenido y revisa la actividad del blog.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: indicadores.map((dato) {
                return SizedBox(
                  width: 220,
                  child: caja(
                    hijo: Row(
                      children: [
                        Icon(dato.$3, color: rojoClaro, size: 30),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${datos[dato.$2]}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              dato.$1,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _RecursoAdmin {
  final String ruta;
  final String nombre;
  final IconData icono;
  final List<_CampoAdmin> campos;

  const _RecursoAdmin({
    required this.ruta,
    required this.nombre,
    required this.icono,
    required this.campos,
  });

  String titulo(Map<String, dynamic> item) =>
      (item[campos.first.clave] ?? '').toString();
}

class _CampoAdmin {
  final String etiqueta;
  final String clave;
  final bool multilinea;
  final bool numerico;
  final bool opcional;

  const _CampoAdmin(
    this.etiqueta,
    this.clave, {
    this.multilinea = false,
    this.numerico = false,
    this.opcional = false,
  });
}

class _CatalogoAdminPage extends StatefulWidget {
  final _RecursoAdmin recurso;

  const _CatalogoAdminPage({required this.recurso});

  @override
  State<_CatalogoAdminPage> createState() => _CatalogoAdminPageState();
}

class _CatalogoAdminPageState extends State<_CatalogoAdminPage> {
  late Future<dynamic> registros;

  @override
  void initState() {
    super.initState();
    registros = Api.get('/admin/${widget.recurso.ruta}');
  }

  void actualizar() => setState(
        () => registros = Api.get('/admin/${widget.recurso.ruta}'),
      );

  Future<void> editar([Map<String, dynamic>? registro]) async {
    final recurso = widget.recurso;
    final formulario = GlobalKey<FormState>();
    final controladores = {
      for (final campo in recurso.campos)
        campo.clave: TextEditingController(
          text: registro?[campo.clave]?.toString() ?? '',
        ),
    };
    final guardado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text(
          registro == null
              ? 'Nuevo ${recurso.nombre}'
              : 'Editar ${recurso.nombre}',
        ),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formulario,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: recurso.campos.map((campo) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: controladores[campo.clave],
                      maxLength: campo.numerico ? 12 : 6000,
                      maxLines: campo.multilinea ? 4 : 1,
                      keyboardType: campo.numerico
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: campo.etiqueta,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        final texto = valor?.trim() ?? '';
                        if (!campo.opcional && texto.isEmpty) {
                          return 'Este campo es obligatorio';
                        }
                        if (texto.isNotEmpty && campo.numerico) {
                          final esEntero =
                              campo.clave == 'anio' || campo.clave == 'stock';
                          if (esEntero && int.tryParse(texto) == null) {
                            return 'Escribe un número entero';
                          }
                          if (!esEntero && double.tryParse(texto) == null) {
                            return 'Escribe un número válido';
                          }
                        }
                        return null;
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formulario.currentState!.validate()) return;
              try {
                final valores = <String, dynamic>{};
                for (final campo in recurso.campos) {
                  final texto = controladores[campo.clave]!.text.trim();
                  if (campo.opcional && texto.isEmpty) {
                    valores[campo.clave] = null;
                  } else if (campo.numerico &&
                      (campo.clave == 'anio' || campo.clave == 'stock')) {
                    valores[campo.clave] = int.parse(texto);
                  } else if (campo.numerico) {
                    valores[campo.clave] = double.parse(texto);
                  } else {
                    valores[campo.clave] = texto;
                  }
                }
                final id = registro?['id'];
                if (id == null) {
                  await Api.post('/admin/${recurso.ruta}', valores);
                } else {
                  await Api.put('/admin/${recurso.ruta}/$id', valores);
                }
                if (dialogo.mounted) Navigator.pop(dialogo, true);
              } catch (e) {
                if (dialogo.mounted) aviso(dialogo, errorTexto(e));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    for (final controlador in controladores.values) {
      controlador.dispose();
    }
    if (guardado == true && mounted) actualizar();
  }

  Future<void> eliminar(Map<String, dynamic> registro) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar "${widget.recurso.titulo(registro)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    try {
      await Api.delete('/admin/${widget.recurso.ruta}/${registro['id']}');
      actualizar();
    } catch (e) {
      if (mounted) aviso(context, errorTexto(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final recurso = widget.recurso;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Gestionar ${recurso.ruta}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: rojoClaro,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: actualizar,
                icon: const Icon(Icons.refresh),
              ),
              ElevatedButton.icon(
                onPressed: () => editar(),
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<dynamic>(
            future: registros,
            builder: (context, estado) {
              if (!estado.hasData && !estado.hasError) {
                return const Center(child: CircularProgressIndicator());
              }
              if (estado.hasError) {
                return _ErrorAdmin(
                  mensaje: errorTexto(estado.error!),
                  reintentar: actualizar,
                );
              }
              final lista = estado.data as List<dynamic>;
              if (lista.isEmpty) {
                return const Center(child: Text('Todavía no hay registros.'));
              }
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: lista.map((dato) {
                  final item = dato as Map<String, dynamic>;
                  return caja(
                    hijo: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(recurso.icono, color: rojoClaro),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recurso.titulo(item),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...recurso.campos.skip(1).map((campo) {
                                final valor = item[campo.clave];
                                if (valor == null || valor.toString().isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final texto = campo.clave == 'precio'
                                    ? '\$$valor MXN'
                                    : '${campo.etiqueta}: $valor';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Text(
                                    texto,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Editar',
                          onPressed: () => editar(item),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Eliminar',
                          onPressed: () => eliminar(item),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ModeracionAdminPage extends StatefulWidget {
  const _ModeracionAdminPage();

  @override
  State<_ModeracionAdminPage> createState() => _ModeracionAdminPageState();
}

class _ModeracionAdminPageState extends State<_ModeracionAdminPage> {
  late Future<dynamic> publicaciones;

  @override
  void initState() {
    super.initState();
    publicaciones = Api.get('/admin/publicaciones');
  }

  void actualizar() =>
      setState(() => publicaciones = Api.get('/admin/publicaciones'));

  Future<void> eliminar(int id, String titulo) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: Text(
            'Se eliminarán también sus comentarios y reacciones.\n\n"$titulo"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    try {
      await Api.delete('/admin/publicaciones/$id');
      actualizar();
    } catch (e) {
      if (mounted) aviso(context, errorTexto(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: publicaciones,
      builder: (context, estado) {
        if (!estado.hasData && !estado.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (estado.hasError) {
          return _ErrorAdmin(
            mensaje: errorTexto(estado.error!),
            reintentar: actualizar,
          );
        }
        final lista = estado.data as List<dynamic>;
        if (lista.isEmpty) {
          return const Center(child: Text('No hay publicaciones que moderar.'));
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: lista.map((dato) {
            final item = dato as Map<String, dynamic>;
            return caja(
              hijo: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['titulo'].toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Eliminar publicación',
                        onPressed: () => eliminar(
                          item['id'] as int,
                          item['titulo'].toString(),
                        ),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  Text(
                    'Por ${item['nombre']} · ${item['comentarios']} comentarios · ${item['fecha']}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(item['contenido'].toString()),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ListaAdminPage extends StatefulWidget {
  final String ruta;
  final String titulo;
  final IconData icono;
  final String Function(Map<String, dynamic>) encabezado;
  final String Function(Map<String, dynamic>) detalle;
  final bool monto;

  const _ListaAdminPage({
    required this.ruta,
    required this.titulo,
    required this.icono,
    required this.encabezado,
    required this.detalle,
    this.monto = false,
  });

  @override
  State<_ListaAdminPage> createState() => _ListaAdminPageState();
}

class _UsuariosAdminPage extends StatefulWidget {
  const _UsuariosAdminPage();

  @override
  State<_UsuariosAdminPage> createState() => _UsuariosAdminPageState();
}

class _UsuariosAdminPageState extends State<_UsuariosAdminPage> {
  late Future<dynamic> usuarios;

  @override
  void initState() {
    super.initState();
    usuarios = Api.get('/admin/usuarios');
  }

  void actualizar() => setState(() => usuarios = Api.get('/admin/usuarios'));

  Future<void> crearAdmin() async {
    final formulario = GlobalKey<FormState>();
    var nombre = '';
    var correo = '';
    var contrasena = '';
    final creado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        scrollable: true,
        title: const Text('Crear administrador'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formulario,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  maxLength: 60,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (valor) => (valor?.trim().length ?? 0) < 2
                      ? 'Escribe al menos 2 caracteres'
                      : null,
                  onSaved: (valor) {
                    nombre = valor?.trim() ?? '';
                  },
                ),
                TextFormField(
                  maxLength: 120,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo'),
                  validator: (valor) {
                    final email = valor?.trim() ?? '';
                    return email.contains('@') &&
                            email.split('@').last.contains('.')
                        ? null
                        : 'Escribe un correo válido';
                  },
                  onSaved: (valor) {
                    correo = valor?.trim() ?? '';
                  },
                ),
                TextFormField(
                  maxLength: 100,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña inicial (mínimo 8 caracteres)',
                  ),
                  validator: (valor) => (valor?.length ?? 0) < 8
                      ? 'Debe tener al menos 8 caracteres'
                      : null,
                  onSaved: (valor) {
                    contrasena = valor ?? '';
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final estado = formulario.currentState!;
              if (!estado.validate()) return;
              estado.save();
              try {
                await Api.post('/admin/usuarios', {
                  'nombre': nombre,
                  'correo': correo,
                  'contrasena': contrasena,
                });
                if (dialogo.mounted) Navigator.pop(dialogo, true);
              } catch (e) {
                if (dialogo.mounted) aviso(dialogo, errorTexto(e));
              }
            },
            child: const Text('Crear administrador'),
          ),
        ],
      ),
    );
    if (creado == true && mounted) {
      actualizar();
      aviso(context, 'Cuenta administradora creada');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: usuarios,
      builder: (context, estado) {
        if (!estado.hasData && !estado.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (estado.hasError) {
          return _ErrorAdmin(
            mensaje: errorTexto(estado.error!),
            reintentar: actualizar,
          );
        }
        final lista = estado.data as List<dynamic>;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cuentas registradas (${lista.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: rojoClaro,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualizar',
                    onPressed: actualizar,
                    icon: const Icon(Icons.refresh),
                  ),
                  ElevatedButton.icon(
                    onPressed: crearAdmin,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Crear admin'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: lista.isEmpty
                  ? const Center(child: Text('No hay cuentas registradas.'))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: lista.map((dato) {
                        final item = dato as Map<String, dynamic>;
                        final esAdmin =
                            item['es_admin'] == true || item['es_admin'] == 1;
                        return caja(
                          hijo: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              esAdmin
                                  ? Icons.admin_panel_settings
                                  : Icons.person_outline,
                              color: rojoClaro,
                            ),
                            title: Text(item['nombre'].toString()),
                            subtitle: Text(
                              '${item['correo']}\n${esAdmin ? 'Administrador' : 'Miembro'} · Alta: ${item['creado_en']}',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ListaAdminPageState extends State<_ListaAdminPage> {
  late Future<dynamic> registros;

  @override
  void initState() {
    super.initState();
    registros = Api.get(widget.ruta);
  }

  void actualizar() => setState(() => registros = Api.get(widget.ruta));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: registros,
      builder: (context, estado) {
        if (!estado.hasData && !estado.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (estado.hasError) {
          return _ErrorAdmin(
            mensaje: errorTexto(estado.error!),
            reintentar: actualizar,
          );
        }
        final lista = estado.data as List<dynamic>;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.titulo} (${lista.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: rojoClaro,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualizar',
                    onPressed: actualizar,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Expanded(
              child: lista.isEmpty
                  ? const Center(child: Text('No hay registros.'))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: lista.map((dato) {
                        final item = dato as Map<String, dynamic>;
                        return caja(
                          hijo: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(widget.icono, color: rojoClaro),
                            title: Text(widget.encabezado(item)),
                            subtitle: Text(widget.detalle(item)),
                            trailing: widget.monto
                                ? Text('\$${item['total']} MXN')
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ErrorAdmin extends StatelessWidget {
  final String mensaje;
  final VoidCallback reintentar;

  const _ErrorAdmin({required this.mensaje, required this.reintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: rojoClaro, size: 36),
            const SizedBox(height: 8),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: reintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
