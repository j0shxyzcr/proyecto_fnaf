import 'package:flutter/material.dart';

// Colores sencillos basados en el ambiente de FNAF 4.
const fondo = Color(0xFF0B0707);
const tarjeta = Color(0xFF3A0D0D);
const rojo = Color(0xFFB71C1C);
const rojoClaro = Color(0xFFE53935);

Widget caja({required Widget hijo}) {
  return Card(
    color: tarjeta,
    elevation: 4,
    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: hijo,
    ),
  );
}

void aviso(BuildContext context, String texto) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
}

String errorTexto(Object e) => e.toString().replaceFirst('Exception: ', '');
