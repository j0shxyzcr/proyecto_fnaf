# Explicación sencilla para exponer el proyecto

## Qué hicimos

Hicimos un blog de FNAF con Flutter. Tiene colores negros y rojos porque nos inspiramos en el ambiente del cuarto juego. Queríamos que se viera como una práctica de estudiantes y por eso usamos botones normales, tarjetas simples y pocas pantallas.

## Cómo funciona

1. El usuario abre la app de Flutter.
2. La app manda una petición HTTP a FastAPI.
3. FastAPI consulta o guarda información en **MySQL instalado en la Mac**.
4. FastAPI regresa los datos como JSON.
5. Flutter los muestra en pantalla.

```text
Flutter ---> HTTP ---> FastAPI ---> MySQL local
Flutter <--- JSON <--- FastAPI <--- MySQL local
```

## Tablas de la base de datos

- `usuarios`: datos de cuenta y hash de contraseña.
- `lore`: textos para explicar la historia de FNAF.
- `juegos`: información sobre juegos de la saga.
- `videos`: episodios del vlog y enlaces de YouTube.
- `publicaciones`: posts de los usuarios.
- `comentarios`: respuestas a publicaciones.
- `reacciones`: una reacción por usuario por post.
- `productos`: peluches de ejemplo, con precios ficticios.
- `pedidos` y `detalle_pedido`: pedidos de prueba y productos que incluyen.

## Relación entre tablas (modelo de datos simple)

```text
usuarios 1 ------ N publicaciones
usuarios 1 ------ N comentarios
usuarios 1 ------ N reacciones
publicaciones 1 -- N comentarios
publicaciones 1 -- N reacciones
usuarios 1 ------ N pedidos
pedidos 1 ------- N detalle_pedido
productos 1 ----- N detalle_pedido
```

## Clases principales (diagrama sencillo)

```text
BlogFnaf
  |-- LoginPage
  |-- PantallaPrincipal
       |-- InicioPage
       |-- DatosPage (Lore y Juegos)
       |-- ComunidadPage
       |-- TiendaPage

Api
  |-- get(ruta)
  |-- post(ruta, datos)
```

## Seguridad

La contraseña no se almacena como texto, sino como un hash calculado por Argon2 en la API. Para entrar se usa un token JWT que dura dos horas. Solo usuarios que iniciaron sesión pueden publicar, comentar, reaccionar y hacer pedidos. El token se guarda temporalmente en memoria en Flutter y se borra al cerrar sesión o reiniciar la app. El archivo `.env` contiene las claves y no debe subirse a GitHub. Al trabajar en HTTP local, el proyecto NO es apto para internet público.

## Multimedia y sensores

Usamos íconos de Flutter y emoji para las reacciones. Los videos, cuando estén disponibles, se abrirán mediante `url_launcher`. No usamos GPS, cámara ni sensores porque no son necesarios para el blog escolar.

## Librerías principales

- Flutter: interfaz móvil/web.
- `http`: conexión de Flutter con FastAPI.
- `url_launcher`: abrir videos de YouTube.
- FastAPI: crear rutas HTTP.
- `mysql-connector-python`: acceso a MySQL.
- `pwdlib[argon2]`: guardar hashes de contraseña.
- `PyJWT`: tokens de sesión.
- `python-dotenv`: leer credenciales de un archivo de configuración.

## Evidencias que faltan (hacerlas realmente en la Mac)

1. Foto de registro/inicio de sesión funcionando.
2. Foto de un usuario nuevo en la tabla `usuarios`.
3. Foto de una publicación y su fila en MySQL.
4. Foto de comentarios y reacciones.
5. Foto del carrito y pedido simulado guardado en MySQL.
6. Foto de `/docs` con la API ejecutándose.

## Reflexión de ejemplo (personalicen según su experiencia real)

Aprendimos a dividir un proyecto en tres partes: Flutter para las pantallas, FastAPI para procesar las solicitudes y MySQL para guardar los datos. Nos costó entender cómo se conectaban las tres, pero el proyecto nos ayudó a practicar registros, consultas y publicaciones. Para mejorar después podríamos agregar fotos a los posts y un sistema de pagos real. **No presenten esta reflexión como una experiencia que aún no han realizado.**

## Limitaciones

- El carrito registra pedidos de prueba: no procesa pagos.
- Solo hay publicaciones de texto, no carga de fotos.
- El contenido de FNAF está resumido y algunas teorías no son hechos confirmados.
- No hay panel para administrar lore o productos desde Flutter; se editan en MySQL local.
- Hay que probar todo en la Mac: esta entrega se creó sin ejecutar Flutter ni una base de datos MySQL real.
