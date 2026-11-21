"""API sencilla para el blog escolar FNAF (MySQL local)."""
import os
from datetime import datetime, timedelta, timezone

import jwt
import mysql.connector
from dotenv import load_dotenv
from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from mysql.connector import IntegrityError
from pydantic import BaseModel, Field
from pwdlib import PasswordHash

load_dotenv()
app = FastAPI(title="Blog FNAF - API escolar")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8080", "http://127.0.0.1:8080"],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Authorization", "Content-Type"],
)

# Este secreto se configura en backend/.env, no se escribe dentro de la app.
SECRET = os.getenv("JWT_SECRET", "")
if len(SECRET) < 32 or SECRET.startswith("PEGA_AQUI"):
    raise RuntimeError("Configura un JWT_SECRET seguro en backend/.env")

hasher = PasswordHash.recommended()
seguridad = HTTPBearer(auto_error=False)


def conexion():
    """Abre una conexión a MySQL LOCAL por cada petición."""
    try:
        db = mysql.connector.connect(
            host=os.getenv("MYSQL_HOST", "127.0.0.1"),
            port=int(os.getenv("MYSQL_PORT", "3306")),
            user=os.getenv("MYSQL_USER", "fnaf_app"),
            password=os.getenv("MYSQL_PASSWORD", ""),
            database=os.getenv("MYSQL_DATABASE", "fnaf_blog"),
            charset="utf8mb4",
            autocommit=True,  # Para que las lecturas no abran una transaccion antes del pedido.
        )
    except mysql.connector.Error:
        raise HTTPException(503, "No se pudo conectar con MySQL local")
    try:
        yield db
    finally:
        db.close()


def uno(db, sql, parametros=()):
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(sql, parametros)
        return cursor.fetchone()
    finally:
        cursor.close()


def varios(db, sql, parametros=()):
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(sql, parametros)
        return cursor.fetchall()
    finally:
        cursor.close()


def ejecutar(db, sql, parametros=()):
    cursor = db.cursor()
    try:
        cursor.execute(sql, parametros)
        identificador = cursor.lastrowid
        db.commit()
        return identificador
    except Exception:
        db.rollback()
        raise
    finally:
        cursor.close()


def usuario_actual(
    credenciales: HTTPAuthorizationCredentials = Depends(seguridad),
    db=Depends(conexion),
):
    if credenciales is None or credenciales.scheme.lower() != "bearer":
        raise HTTPException(401, "Necesitas iniciar sesión")
    try:
        datos = jwt.decode(credenciales.credentials, SECRET, algorithms=["HS256"])
        usuario_id = int(datos["sub"])
    except (jwt.PyJWTError, KeyError, ValueError, TypeError):
        raise HTTPException(401, "Tu sesión no es válida o expiró")
    usuario = uno(db, "SELECT id, nombre, correo FROM usuarios WHERE id = %s", (usuario_id,))
    if not usuario:
        raise HTTPException(401, "La cuenta ya no existe")
    return usuario


class Registro(BaseModel):
    nombre: str = Field(min_length=2, max_length=60)
    correo: str = Field(min_length=5, max_length=120)
    contrasena: str = Field(min_length=8, max_length=100)


class Login(BaseModel):
    correo: str
    contrasena: str


class Publicacion(BaseModel):
    titulo: str = Field(min_length=2, max_length=120)
    contenido: str = Field(min_length=2, max_length=2000)


class Comentario(BaseModel):
    contenido: str = Field(min_length=1, max_length=500)


class Reaccion(BaseModel):
    tipo: str


class Articulo(BaseModel):
    producto_id: int = Field(gt=0)
    cantidad: int = Field(gt=0, le=20)


class Pedido(BaseModel):
    articulos: list[Articulo] = Field(min_length=1)


@app.get("/health")
def salud(db=Depends(conexion)):
    uno(db, "SELECT 1 AS listo")
    return {"api": "ok", "mysql": "conectado"}


@app.post("/registro", status_code=201)
def registrar(datos: Registro, db=Depends(conexion)):
    correo = datos.correo.strip().lower()
    nombre = datos.nombre.strip()
    if not nombre or "@" not in correo or "." not in correo.split("@")[-1]:
        raise HTTPException(400, "Revisa el nombre y correo")
    try:
        nuevo_id = ejecutar(
            db,
            "INSERT INTO usuarios (nombre, correo, contrasena_hash) VALUES (%s, %s, %s)",
            (nombre, correo, hasher.hash(datos.contrasena)),
        )
    except IntegrityError:
        raise HTTPException(409, "Este correo ya está registrado")
    return {"id": nuevo_id, "mensaje": "Cuenta creada"}


@app.post("/login")
def login(datos: Login, db=Depends(conexion)):
    usuario = uno(db, "SELECT * FROM usuarios WHERE correo = %s", (datos.correo.strip().lower(),))
    if usuario is None or not hasher.verify(datos.contrasena, usuario["contrasena_hash"]):
        raise HTTPException(401, "Correo o contraseña incorrectos")
    vencimiento = datetime.now(timezone.utc) + timedelta(hours=2)
    token = jwt.encode({"sub": str(usuario["id"]), "exp": vencimiento}, SECRET, algorithm="HS256")
    return {"token": token, "nombre": usuario["nombre"]}


@app.get("/yo")
def yo(usuario=Depends(usuario_actual)):
    return usuario


@app.get("/lore")
def obtener_lore(db=Depends(conexion)):
    return varios(db, "SELECT id, titulo, contenido FROM lore ORDER BY id")


@app.get("/juegos")
def obtener_juegos(db=Depends(conexion)):
    return varios(db, "SELECT id, titulo, anio, descripcion FROM juegos ORDER BY id")


@app.get("/videos")
def obtener_videos(db=Depends(conexion)):
    return varios(db, "SELECT id, titulo, descripcion, url FROM videos ORDER BY id")


@app.get("/publicaciones")
def obtener_publicaciones(usuario=Depends(usuario_actual), db=Depends(conexion)):
    return varios(db, """
        SELECT p.id, p.titulo, p.contenido, p.fecha, u.nombre,
               (SELECT COUNT(*) FROM comentarios c WHERE c.publicacion_id = p.id) AS comentarios,
               (SELECT COUNT(*) FROM reacciones r WHERE r.publicacion_id = p.id) AS reacciones,
               (SELECT tipo FROM reacciones r WHERE r.publicacion_id = p.id
                   AND r.usuario_id = %s) AS mi_reaccion
        FROM publicaciones p JOIN usuarios u ON p.usuario_id = u.id
        ORDER BY p.id DESC LIMIT 100
    """, (usuario["id"],))


@app.post("/publicaciones", status_code=201)
def crear_publicacion(datos: Publicacion, usuario=Depends(usuario_actual), db=Depends(conexion)):
    nuevo_id = ejecutar(
        db, "INSERT INTO publicaciones (usuario_id, titulo, contenido) VALUES (%s, %s, %s)",
        (usuario["id"], datos.titulo.strip(), datos.contenido.strip()),
    )
    return {"id": nuevo_id, "mensaje": "Publicación creada"}


@app.get("/publicaciones/{publicacion_id}/comentarios")
def obtener_comentarios(publicacion_id: int, usuario=Depends(usuario_actual), db=Depends(conexion)):
    if not uno(db, "SELECT id FROM publicaciones WHERE id=%s", (publicacion_id,)):
        raise HTTPException(404, "No existe la publicación")
    return varios(db, """
        SELECT c.id, c.contenido, c.fecha, u.nombre
        FROM comentarios c JOIN usuarios u ON c.usuario_id = u.id
        WHERE c.publicacion_id = %s ORDER BY c.id
    """, (publicacion_id,))


@app.post("/publicaciones/{publicacion_id}/comentarios", status_code=201)
def crear_comentario(publicacion_id: int, datos: Comentario, usuario=Depends(usuario_actual), db=Depends(conexion)):
    if not uno(db, "SELECT id FROM publicaciones WHERE id=%s", (publicacion_id,)):
        raise HTTPException(404, "No existe la publicación")
    identificador = ejecutar(
        db, "INSERT INTO comentarios (publicacion_id, usuario_id, contenido) VALUES (%s,%s,%s)",
        (publicacion_id, usuario["id"], datos.contenido.strip()),
    )
    return {"id": identificador}


@app.post("/publicaciones/{publicacion_id}/reaccion")
def reaccionar(publicacion_id: int, datos: Reaccion, usuario=Depends(usuario_actual), db=Depends(conexion)):
    if datos.tipo not in ("like", "love", "haha", "wow", "sad", "angry"):
        raise HTTPException(400, "Reacción no permitida")
    if not uno(db, "SELECT id FROM publicaciones WHERE id=%s", (publicacion_id,)):
        raise HTTPException(404, "No existe la publicación")
    anterior = uno(db, """
        SELECT tipo FROM reacciones WHERE publicacion_id=%s AND usuario_id=%s
    """, (publicacion_id, usuario["id"]))
    if anterior and anterior["tipo"] == datos.tipo:
        ejecutar(db, "DELETE FROM reacciones WHERE publicacion_id=%s AND usuario_id=%s",
                 (publicacion_id, usuario["id"]))
        return {"mensaje": "Reacción quitada"}
    ejecutar(db, """
        INSERT INTO reacciones (publicacion_id, usuario_id, tipo) VALUES (%s,%s,%s)
        ON DUPLICATE KEY UPDATE tipo=VALUES(tipo)
    """, (publicacion_id, usuario["id"], datos.tipo))
    return {"mensaje": "Reacción guardada"}


@app.get("/productos")
def productos(db=Depends(conexion)):
    return varios(db, "SELECT id, nombre, descripcion, precio, stock FROM productos ORDER BY id")


@app.post("/pedidos", status_code=201)
def nuevo_pedido(datos: Pedido, usuario=Depends(usuario_actual), db=Depends(conexion)):
    # Pedidos de DEMOSTRACION: no se cobra dinero ni se procesan pagos.
    cantidades = {}
    for articulo in datos.articulos:
        cantidades[articulo.producto_id] = cantidades.get(articulo.producto_id, 0) + articulo.cantidad
    if len(cantidades) > 20 or any(cantidad > 20 for cantidad in cantidades.values()):
        raise HTTPException(400, "Cantidad demasiado grande")
    cursor = db.cursor(dictionary=True)
    try:
        db.start_transaction()
        productos_elegidos = []
        total = 0
        for producto_id in sorted(cantidades):
            cursor.execute("SELECT id, precio, stock FROM productos WHERE id=%s FOR UPDATE", (producto_id,))
            producto = cursor.fetchone()
            cantidad = cantidades[producto_id]
            if not producto or producto["stock"] < cantidad:
                raise HTTPException(400, f"No hay stock suficiente del producto {producto_id}")
            productos_elegidos.append((producto, cantidad))
            total += producto["precio"] * cantidad
        cursor.execute("INSERT INTO pedidos (usuario_id, total, estado) VALUES (%s,%s,'simulado')",
                       (usuario["id"], total))
        pedido_id = cursor.lastrowid
        for producto, cantidad in productos_elegidos:
            cursor.execute("""
                INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario)
                VALUES (%s,%s,%s,%s)
            """, (pedido_id, producto["id"], cantidad, producto["precio"]))
            cursor.execute("UPDATE productos SET stock=stock-%s WHERE id=%s", (cantidad, producto["id"]))
        db.commit()
        return {"pedido_id": pedido_id, "total": float(total), "estado": "simulado"}
    except Exception:
        db.rollback()
        raise
    finally:
        cursor.close()


@app.get("/mis-pedidos")
def mis_pedidos(usuario=Depends(usuario_actual), db=Depends(conexion)):
    return varios(db, """
        SELECT id, total, estado, fecha FROM pedidos WHERE usuario_id=%s ORDER BY id DESC
    """, (usuario["id"],))
