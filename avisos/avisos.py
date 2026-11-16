import json
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

AVISOS = [
    "Por lluvia, la proyeccion del viernes pasa al polideportivo",
    "La sesion del domingo se retrasa a las 23:00 por tormenta",
]


class MiServidor(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/avisos":
            self.enviar_json(200, AVISOS)
        else:
            self.enviar_json(404, {"error": "No existe"})

    def do_POST(self):
        longitud = int(self.headers.get("Content-Length", 0))
        texto = self.rfile.read(longitud).decode("utf-8").strip()
        if self.path == "/avisos" and texto:
            AVISOS.append(texto)
            self.enviar_json(201, {"nuevo": texto, "avisos": len(AVISOS)})
        else:
            self.enviar_json(404, {"error": "No existe"})

    def enviar_json(self, estado, objeto):
        datos = (json.dumps(objeto, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
        self.send_response(estado)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(datos)))
        self.end_headers()
        self.wfile.write(datos)

        momento = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
        linea = f'{self.client_address[0]} [{momento}] "{self.command} {self.path}" {estado} {len(datos)}'
        with open("../trabajo1/logs/avisos.log", "a", encoding="utf-8") as f:
            f.write(linea + "\n")


ThreadingHTTPServer.allow_reuse_address = False
print("Avisos en http://127.0.0.1:8001/avisos  (Ctrl+C para parar)")
try:
    ThreadingHTTPServer(("127.0.0.1", 8001), MiServidor).serve_forever()
except KeyboardInterrupt:
    print("Servidor parado.")