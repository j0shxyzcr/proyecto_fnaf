-- Blog escolar de FNAF: base de datos LOCAL MySQL
-- Los contenidos son de ejemplo para una practica, no datos comerciales reales.
CREATE DATABASE IF NOT EXISTS fnaf_blog CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE fnaf_blog;
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(60) NOT NULL,
  correo VARCHAR(120) NOT NULL UNIQUE,
  contrasena_hash VARCHAR(255) NOT NULL,
  es_admin BOOLEAN NOT NULL DEFAULT FALSE,
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS lore (
  id INT AUTO_INCREMENT PRIMARY KEY,
  titulo VARCHAR(150) NOT NULL,
  contenido TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS juegos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  titulo VARCHAR(100) NOT NULL,
  anio INT NOT NULL,
  descripcion TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS videos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  titulo VARCHAR(150) NOT NULL,
  descripcion TEXT NOT NULL,
  url VARCHAR(400) NULL
);

CREATE TABLE IF NOT EXISTS publicaciones (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  titulo VARCHAR(120) NOT NULL,
  contenido TEXT NOT NULL,
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

CREATE TABLE IF NOT EXISTS comentarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  publicacion_id INT NOT NULL,
  usuario_id INT NOT NULL,
  contenido VARCHAR(500) NOT NULL,
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (publicacion_id) REFERENCES publicaciones(id) ON DELETE CASCADE,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

CREATE TABLE IF NOT EXISTS reacciones (
  id INT AUTO_INCREMENT PRIMARY KEY,
  publicacion_id INT NOT NULL,
  usuario_id INT NOT NULL,
  tipo ENUM('like', 'love', 'haha', 'wow', 'sad', 'angry') NOT NULL,
  UNIQUE KEY unica_reaccion (publicacion_id, usuario_id),
  FOREIGN KEY (publicacion_id) REFERENCES publicaciones(id) ON DELETE CASCADE,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

CREATE TABLE IF NOT EXISTS productos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL,
  descripcion VARCHAR(500) NOT NULL,
  precio DECIMAL(10,2) NOT NULL,
  stock INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS pedidos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  estado VARCHAR(30) NOT NULL DEFAULT 'simulado',
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

CREATE TABLE IF NOT EXISTS detalle_pedido (
  id INT AUTO_INCREMENT PRIMARY KEY,
  pedido_id INT NOT NULL,
  producto_id INT NOT NULL,
  cantidad INT NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (pedido_id) REFERENCES pedidos(id),
  FOREIGN KEY (producto_id) REFERENCES productos(id)
);

-- Se usan ids fijos para actualizar los datos de ejemplo sin duplicarlos.
INSERT INTO lore (id, titulo, contenido) VALUES
(1, '¿Qué es FNAF?', 'Five Nights at Freddy''s es una saga de terror donde aparecen animatronicos, guardias nocturnos y muchos misterios. En este blog contaremos lo que sucede en los juegos y algunas teorias de los fans.'),
(2, 'Fredbear y los primeros misterios', 'Fredbear y Spring Bonnie forman parte de los primeros recuerdos de la historia. Algunos detalles de su pasado siguen siendo tema de debate entre los fans.'),
(3, 'La mordida del 83', 'En FNAF 4 aparece una escena muy importante relacionada con un cumpleaños y Fredbear. Es una de las pistas principales para hablar del pasado de la saga.'),
(4, 'Los animatronicos', 'Freddy, Bonnie, Chica y Foxy son personajes clasicos. Cada entrega agrega personajes e historias nuevas.'),
(5, 'Teorias del lore', 'No toda la cronologia tiene una unica interpretacion. Aqui podemos separar lo mostrado directamente en los juegos de las teorias de la comunidad.')
ON DUPLICATE KEY UPDATE titulo=VALUES(titulo), contenido=VALUES(contenido);

INSERT INTO juegos (id, titulo, anio, descripcion) VALUES
(1, 'Five Nights at Freddy''s', 2014, 'Trabajas como guardia de noche y debes vigilar las camaras mientras administras la energia.'),
(2, 'Five Nights at Freddy''s 2', 2014, 'Regresan los animatronicos y aparecen nuevas mecanicas, como la mascara de Freddy.'),
(3, 'Five Nights at Freddy''s 3', 2015, 'La historia continua en Fazbear''s Fright, una atraccion de terror.'),
(4, 'Five Nights at Freddy''s 4', 2015, 'Una habitacion oscura, pasillos, puertas y pesadillas. Este juego inspira los colores de nuestra app.'),
(5, 'Five Nights at Freddy''s: Sister Location', 2016, 'Conoces nuevas instalaciones y animatronicos.'),
(6, 'Freddy Fazbear''s Pizzeria Simulator', 2017, 'Administracion de una pizzeria y secretos de la historia.'),
(7, 'Five Nights at Freddy''s: Help Wanted', 2019, 'Experiencias de terror con minijuegos, originalmente pensadas para realidad virtual.'),
(8, 'Five Nights at Freddy''s: Security Breach', 2021, 'Exploras el enorme Mega Pizzaplex y conoces nuevos personajes.')
ON DUPLICATE KEY UPDATE titulo=VALUES(titulo), anio=VALUES(anio), descripcion=VALUES(descripcion);

INSERT INTO videos (id, titulo, descripcion, url) VALUES
(1, 'Episodio 1 - ¿Como empezo FNAF?', 'Aqui pondremos nuestro primer video explicando la historia.', NULL),
(2, 'Episodio 2 - La mordida del 83', 'Video sobre las pistas y escenas de FNAF 4.', NULL)
ON DUPLICATE KEY UPDATE titulo=VALUES(titulo), descripcion=VALUES(descripcion);

-- PRECIOS FICTICIOS. NO son inventario real ni se verifico su procedencia oficial.
INSERT INTO productos (id, nombre, descripcion, precio, stock) VALUES
(1, 'Peluche Freddy (demo)', 'Perdón por no venderlo de verdad :`v', 299.00, 10),
(2, 'Peluche Bonnie (demo)', 'Perdón por no venderlo de verdad :`v', 279.00, 8),
(3, 'Peluche Chica (demo)', 'Perdón por no venderlo de verdad :`v', 279.00, 7),
(4, 'Peluche Foxy (demo)', 'Perdón por no venderlo de verdad :`v', 319.00, 5)
ON DUPLICATE KEY UPDATE nombre=VALUES(nombre), descripcion=VALUES(descripcion), precio=VALUES(precio);
