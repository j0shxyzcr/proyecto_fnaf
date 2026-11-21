import 'package:flutter/material.dart';
import 'api.dart';
import 'estilo.dart';
import 'login_page.dart';
import 'inicio_page.dart';
import 'datos_page.dart';
import 'comunidad_page.dart';
import 'tienda_page.dart';

void main() => runApp(const BlogFnaf());

class BlogFnaf extends StatefulWidget {
  const BlogFnaf({super.key});

  @override
  State<BlogFnaf> createState() => _BlogFnafState();
}

class _BlogFnafState extends State<BlogFnaf> {
  String nombre = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FNAF Blog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
        primaryColor: rojo,
        scaffoldBackgroundColor: fondo,
        cardColor: tarjeta,
        colorScheme:
            const ColorScheme.dark(primary: rojoClaro, secondary: rojo),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF210606)),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              backgroundColor: rojo, foregroundColor: Colors.white),
        ),
      ),
      home: nombre.isEmpty
          ? LoginPage(alEntrar: (n) => setState(() => nombre = n))
          : PantallaPrincipal(
              nombre: nombre,
              alSalir: () {
                Api.token = '';
                setState(() => nombre = '');
              },
            ),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  final String nombre;
  final VoidCallback alSalir;
  const PantallaPrincipal(
      {super.key, required this.nombre, required this.alSalir});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int pagina = 0;

  @override
  Widget build(BuildContext context) {
    final pantallas = [
      InicioPage(nombre: widget.nombre),
      const DatosPage(key: ValueKey('lore'), titulo: 'LORE', ruta: '/lore'),
      const DatosPage(
          key: ValueKey('juegos'), titulo: 'JUEGOS', ruta: '/juegos'),
      const ComunidadPage(),
      const TiendaPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('FNAF BLOG', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: widget.alSalir,
          ),
        ],
      ),
      // IndexedStack conserva el carrito al cambiar de sección.
      body: IndexedStack(index: pagina, children: pantallas),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF210606),
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: pagina,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        onTap: (indice) => setState(() => pagina = indice),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Lore'),
          BottomNavigationBarItem(
              icon: Icon(Icons.videogame_asset), label: 'Juegos'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Comunidad'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Tienda'),
        ],
      ),
    );
  }
}
