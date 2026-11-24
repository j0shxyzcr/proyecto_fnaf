"""Promueve una cuenta existente a administradora en MySQL local."""
import os
import sys
from pathlib import Path

import mysql.connector
from dotenv import load_dotenv

load_dotenv(Path(__file__).with_name(".env"))


def main():
    if len(sys.argv) != 2 or not sys.argv[1].strip():
        raise SystemExit(
            "Uso: python backend/configurar_admin.py --migrar | correo@ejemplo.com"
        )

    migrar_solo = sys.argv[1] == "--migrar"
    correo = "" if migrar_solo else sys.argv[1].strip().lower()
    db = mysql.connector.connect(
        host=os.getenv("MYSQL_HOST", "127.0.0.1"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        user=os.getenv("MYSQL_USER", "fnaf_app"),
        password=os.getenv("MYSQL_PASSWORD", ""),
        database=os.getenv("MYSQL_DATABASE", "fnaf_blog"),
        charset="utf8mb4",
    )
    try:
        cursor = db.cursor(dictionary=True)
        try:
            cursor.execute("""
                SELECT COUNT(*) AS existe
                FROM information_schema.columns
                WHERE table_schema=%s AND table_name='usuarios' AND column_name='es_admin'
            """, (os.getenv("MYSQL_DATABASE", "fnaf_blog"),))
            if not cursor.fetchone()["existe"]:
                cursor.execute(
                    "ALTER TABLE usuarios ADD COLUMN es_admin BOOLEAN NOT NULL DEFAULT FALSE"
                )
            if not migrar_solo:
                cursor.execute(
                    "SELECT id, nombre FROM usuarios WHERE correo=%s", (correo,)
                )
                usuario = cursor.fetchone()
                if usuario is None:
                    raise SystemExit(
                        "No existe esa cuenta. Regístrala primero desde la app."
                    )
                cursor.execute(
                    "UPDATE usuarios SET es_admin=TRUE WHERE id=%s", (usuario["id"],)
                )
                db.commit()
        finally:
            cursor.close()
    finally:
        db.close()
    if migrar_solo:
        print("Migración de permisos lista.")
    else:
        print(
            f"Permisos de administrador activados para {usuario['nombre']} ({correo})."
        )


if __name__ == "__main__":
    main()
