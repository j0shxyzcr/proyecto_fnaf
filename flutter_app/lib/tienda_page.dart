import 'package:flutter/material.dart';
import 'api.dart';
import 'estilo.dart';

const _imagenesProductos = <int, String>{
  1: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQC1bLX_3Hs4BC45DynGlq-IvgxDd8FOjSx5in3ME6exw&s=10',
  2: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcStzuXcMH_R7nmroBRHhCU_tn2uip0gShs_ly_NelrjWQ&s=10',
  3: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSCe9D78bpbaH-hWTzPm8nTLcSHIDoaFMo3z6Nr2wWmXQ&s=10',
  4: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSzsZcKcnp4fqYzobiV5j1tmQetK9fJ598K4iciD9r0tg&s=10',
};

Widget _imagenProducto(int id) {
  final url = _imagenesProductos[id];
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 76,
      height: 76,
      child: url == null
          ? const Icon(Icons.toys, color: Colors.redAccent, size: 42)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.toys, color: Colors.redAccent, size: 42),
            ),
    ),
  );
}

class TiendaPage extends StatefulWidget {
  const TiendaPage({super.key});

  @override
  State<TiendaPage> createState() => _TiendaPageState();
}

class _TiendaPageState extends State<TiendaPage> {
  late Future<dynamic> productos;
  final Map<int, int> carrito = {};
  List<dynamic> listaProductos = [];

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void cargar() {
    setState(() {
      productos = Api.get('/productos');
    });
  }

  double get total {
    double suma = 0;
    for (final p in listaProductos) {
      final item = p as Map<String, dynamic>;
      suma += (item['precio'] as num).toDouble() * (carrito[item['id']] ?? 0);
    }
    return suma;
  }

  int get cantidadCarrito =>
      carrito.values.fold(0, (suma, cantidad) => suma + cantidad);

  void agregar(Map<String, dynamic> producto) {
    final id = producto['id'] as int;
    final stock = producto['stock'] as int;
    if ((carrito[id] ?? 0) >= stock) {
      aviso(context, 'Ya agregaste todo el stock disponible');
      return;
    }
    setState(() => carrito[id] = (carrito[id] ?? 0) + 1);
    aviso(context, 'Agregado al carrito');
  }

  Future<void> mostrarCarrito() async {
    await showDialog<void>(
      context: context,
      builder: (ventana) => StatefulBuilder(
        builder: (contexto, cambiarDialogo) => AlertDialog(
          title: const Text('Mi carrito'),
          content: SizedBox(
            width: 330,
            child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (carrito.isEmpty)
                      const Text('No has agregado peluches.'),
                    ...listaProductos
                        .where((p) => carrito.containsKey(p['id']))
                        .map((p) {
                      final item = p as Map<String, dynamic>;
                      final id = item['id'] as int;
                      return Row(children: [
                        Expanded(
                            child: Text('${item['nombre']} x${carrito[id]}')),
                        IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              cambiarDialogo(() {
                                setState(() {
                                  carrito[id] = (carrito[id] ?? 1) - 1;
                                  if (carrito[id] == 0) carrito.remove(id);
                                });
                              });
                            }),
                      ]);
                    }),
                    const SizedBox(height: 12),
                    Text('Total: \$${total.toStringAsFixed(2)} MXN',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text('Pedido de prueba, NO es un pago real.',
                        style:
                            TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ventana),
                child: const Text('Cerrar')),
            ElevatedButton(
              onPressed: carrito.isEmpty
                  ? null
                  : () async {
                      try {
                        final respuesta = await Api.post('/pedidos', {
                          'articulos': carrito.entries
                              .map((e) =>
                                  {'producto_id': e.key, 'cantidad': e.value})
                              .toList(),
                        });
                        if (!contexto.mounted) return;
                        setState(() => carrito.clear());
                        Navigator.pop(ventana);
                        aviso(contexto,
                            'Pedido de PRUEBA #${respuesta['pedido_id']} guardado');
                        cargar();
                      } catch (e) {
                        if (contexto.mounted) {
                          aviso(contexto, errorTexto(e));
                        }
                      }
                    },
              child: const Text('Confirmar prueba'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> verPedidos() async {
    try {
      final lista = await Api.get('/mis-pedidos') as List<dynamic>;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ventana) => AlertDialog(
          title: const Text('Mis pedidos de prueba'),
          content: SizedBox(
            width: 300,
            child: ListView(shrinkWrap: true, children: [
              if (lista.isEmpty) const Text('Todavía no tienes pedidos.'),
              ...lista.map((p) => ListTile(
                    title: Text('Pedido #${p['id']}'),
                    subtitle: Text('Estado: ${p['estado']}'),
                    trailing: Text('\$${p['total']}'),
                  )),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ventana),
                child: const Text('Cerrar'))
          ],
        ),
      );
    } catch (e) {
      if (mounted) aviso(context, errorTexto(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          const Expanded(
              child: Text('TIENDA',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent))),
          IconButton(
              tooltip: 'Mis pedidos',
              onPressed: verPedidos,
              icon: const Icon(Icons.receipt_long)),
          ElevatedButton.icon(
              onPressed: mostrarCarrito,
              icon: const Icon(Icons.shopping_cart, size: 18),
              label: Text('$cantidadCarrito')),
        ]),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text(
            'lamentablemente no vendo peluches de fnaff :`v.',
            style: TextStyle(color: Colors.white60, fontSize: 12)),
      ),
      Expanded(
          child: FutureBuilder<dynamic>(
        future: productos,
        builder: (context, estado) {
          if (!estado.hasData && !estado.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          if (estado.hasError) {
            return Center(child: Text(errorTexto(estado.error!)));
          }
          final lista = estado.data as List<dynamic>;
          // datos para el carrito
          listaProductos = lista;
          return ListView(
              children: lista.map((dato) {
            final p = dato as Map<String, dynamic>;
            return caja(
                hijo: Row(children: [
              _imagenProducto(p['id'] as int),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(p['nombre'].toString(),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    Text(p['descripcion'].toString(),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text('\$${p['precio']} MXN | Stock: ${p['stock']}',
                        style: const TextStyle(color: Colors.redAccent)),
                  ])),
              IconButton(
                tooltip: 'Agregar al carrito',
                onPressed: (p['stock'] as int) > 0 ? () => agregar(p) : null,
                icon: const Icon(Icons.add_shopping_cart,
                    color: Colors.redAccent),
              ),
            ]));
          }).toList());
        },
      )),
    ]);
  }
}
