import 'package:flutter/material.dart';
import 'api.dart';
import 'estilo.dart';

class LoginPage extends StatefulWidget {
  final void Function(String, bool) alEntrar;
  const LoginPage({super.key, required this.alEntrar});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final nombre = TextEditingController();
  final correo = TextEditingController();
  final contrasena = TextEditingController();
  bool registro = false;
  bool cargando = false;

  @override
  void dispose() {
    nombre.dispose();
    correo.dispose();
    contrasena.dispose();
    super.dispose();
  }

  Future<void> entrar() async {
    if (correo.text.trim().isEmpty || contrasena.text.isEmpty) {
      aviso(context, 'Escribe correo y contraseña');
      return;
    }
    setState(() => cargando = true);
    try {
      if (registro) {
        await Api.post('/registro', {
          'nombre': nombre.text.trim(),
          'correo': correo.text.trim(),
          'contrasena': contrasena.text,
        });
      }
      final datos = await Api.post('/login', {
        'correo': correo.text.trim(),
        'contrasena': contrasena.text,
      });
      Api.token = datos['token'].toString();
      final usuario = await Api.get('/yo');
      final esAdmin =
          usuario['es_admin'] == true || usuario['es_admin'] == 1;
      if (mounted) {
        widget.alEntrar(
          datos['nombre'].toString(),
          esAdmin,
        );
      }
    } catch (e) {
      if (mounted) aviso(context, errorTexto(e));
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              children: [
                const Icon(Icons.nightlight_round, size: 75, color: rojoClaro),
                const SizedBox(height: 10),
                const Text('FNAF BLOG',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent)),
                const Text('NO APAGUES LA LUZ...',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                if (registro)
                  TextField(
                    controller: nombre,
                    decoration: const InputDecoration(
                        labelText: 'Nombre', border: OutlineInputBorder()),
                  ),
                if (registro) const SizedBox(height: 12),
                TextField(
                  controller: correo,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Correo', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contrasena,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Contraseña (mínimo 8 caracteres)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cargando ? null : entrar,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(cargando
                          ? 'Cargando...'
                          : registro
                              ? 'Crear cuenta'
                              : 'Entrar'),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: cargando
                      ? null
                      : () => setState(() => registro = !registro),
                  child: Text(registro
                      ? 'Ya tengo cuenta'
                      : '¿No tienes cuenta? Regístrate'),
                ),
                const SizedBox(height: 20),
                const Text('proyecto no oficial.',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
