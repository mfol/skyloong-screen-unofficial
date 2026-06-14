#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SKYLOONG 4.0 Console — servidor local com cache de thumbnails em SQLite.

Usa SOMENTE a biblioteca padrao do Python (http.server + sqlite3). Nada para instalar.

O teclado salva os arquivos com nomes numericos (ex.: 1781402560644.mpeg) e NAO devolve
o conteudo deles. Este servidor guarda, para cada arquivo, uma MINIATURA e um APELIDO,
para voce saber "quem e quem". Ao apagar um arquivo no teclado, o frontend tambem remove
o registro aqui.

Endpoints:
    GET    /api/health            -> {"ok": true}
    GET    /api/thumbs            -> { "<name>": {label,type,size,thumb,ts}, ... }
    PUT    /api/thumb   (JSON)    -> upsert {name,label?,type?,size?,thumb?}
    POST   /api/thumb   (JSON)    -> idem PUT
    DELETE /api/thumb?name=...    -> remove um registro

Tudo o mais e servido como arquivo estatico a partir da pasta deste script.
Banco: thumbnails.sqlite (ao lado deste arquivo).
"""
import http.server
import sqlite3
import json
import os
import threading
import urllib.parse

ROOT = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(ROOT, "thumbnails.sqlite")
PORT = int(os.environ.get("PORT", "8000"))
_LOCK = threading.Lock()


def init_db():
    con = sqlite3.connect(DB_PATH)
    try:
        con.execute("PRAGMA journal_mode=WAL")
        con.execute(
            """CREATE TABLE IF NOT EXISTS thumbs(
                   name  TEXT PRIMARY KEY,
                   label TEXT,
                   type  TEXT,
                   size  INTEGER,
                   thumb TEXT,
                   ts    INTEGER
               )"""
        )
        con.commit()
    finally:
        con.close()


def db_run(fn):
    """Roda fn(con) com lock + commit + close. Serializa o acesso (servidor pequeno)."""
    with _LOCK:
        con = sqlite3.connect(DB_PATH)
        con.row_factory = sqlite3.Row
        try:
            out = fn(con)
            con.commit()
            return out
        finally:
            con.close()


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=ROOT, **k)

    # ---------- helpers ----------
    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET,PUT,POST,DELETE,OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def _json(self, obj, code=200):
        body = json.dumps(obj).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self._cors()
        self.end_headers()
        self.wfile.write(body)

    def _read_json(self):
        n = int(self.headers.get("Content-Length") or 0)
        if not n:
            return {}
        try:
            return json.loads(self.rfile.read(n).decode("utf-8") or "{}")
        except Exception:
            return {}

    # ---------- verbs ----------
    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        path = urllib.parse.urlparse(self.path).path
        if path == "/api/health":
            return self._json({"ok": True})
        if path == "/api/thumbs":
            rows = db_run(lambda c: c.execute("SELECT * FROM thumbs").fetchall())
            out = {}
            for r in rows:
                out[r["name"]] = {
                    "label": r["label"],
                    "type": r["type"],
                    "size": r["size"],
                    "thumb": r["thumb"],
                    "ts": r["ts"],
                }
            return self._json(out)
        return super().do_GET()  # arquivo estatico

    def _upsert(self):
        data = self._read_json()
        name = data.get("name")
        if not name:
            return self._json({"error": "name obrigatorio"}, 400)
        db_run(lambda c: c.execute(
            """INSERT INTO thumbs(name,label,type,size,thumb,ts)
               VALUES(:name,:label,:type,:size,:thumb,:ts)
               ON CONFLICT(name) DO UPDATE SET
                   label=COALESCE(excluded.label, thumbs.label),
                   type =COALESCE(excluded.type,  thumbs.type),
                   size =COALESCE(excluded.size,  thumbs.size),
                   thumb=COALESCE(excluded.thumb, thumbs.thumb),
                   ts   =excluded.ts""",
            {
                "name": name,
                "label": data.get("label"),
                "type": data.get("type"),
                "size": data.get("size"),
                "thumb": data.get("thumb"),
                "ts": data.get("ts") or 0,
            },
        ))
        return self._json({"ok": True})

    def do_PUT(self):
        if urllib.parse.urlparse(self.path).path == "/api/thumb":
            return self._upsert()
        return self._json({"error": "nao encontrado"}, 404)

    def do_POST(self):
        if urllib.parse.urlparse(self.path).path == "/api/thumb":
            return self._upsert()
        return self._json({"error": "nao encontrado"}, 404)

    def do_DELETE(self):
        u = urllib.parse.urlparse(self.path)
        if u.path == "/api/thumb":
            name = (urllib.parse.parse_qs(u.query).get("name") or [None])[0]
            if not name:
                return self._json({"error": "name obrigatorio"}, 400)
            db_run(lambda c: c.execute("DELETE FROM thumbs WHERE name=?", (name,)))
            return self._json({"ok": True})
        return self._json({"error": "nao encontrado"}, 404)

    def log_message(self, *a):
        pass  # silencia o log de cada request


def main():
    init_db()
    server = http.server.ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print("  SKYLOONG 4.0 Console")
    print("  ----------------------------------------")
    print("  Pasta   : %s" % ROOT)
    print("  Banco   : %s" % DB_PATH)
    print("  Abra    : http://localhost:%d/skyloong-ui.html" % PORT)
    print("  (na mesma rede, do celular: http://<ip-do-pc>:%d/skyloong-ui.html)" % PORT)
    print("  Ctrl+C para parar.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  Encerrado.")


if __name__ == "__main__":
    main()
