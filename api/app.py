import time
from flask import Flask, request
from waitress import serve

app = Flask(__name__)

PELICULAS = ["Cinema Paradiso", "El verano de Kikujiro", "Los Goonies"]


@app.route("/api/estado")
def estado():
    return {"estado": "ok"}


@app.route("/api/peliculas")
def peliculas():
    return {"peliculas": PELICULAS}


@app.route("/api/peliculas/<int:n>")
def una_pelicula(n):
    if 1 <= n <= len(PELICULAS):
        return {"n": n, "pelicula": PELICULAS[n - 1]}
    return {"error": "No existe esa pelicula"}, 404


@app.route("/api/lenta")
def lenta():
    time.sleep(2)
    return {"listo": True}


@app.route("/", defaults={"ruta": ""})
@app.route("/<path:ruta>")
def cualquier_ruta(ruta):
    texto = (f"Ruta pedida: /{ruta}\n"
             f"Host: {request.headers.get('Host')}\n"
             f"X-Real-IP: {request.headers.get('X-Real-IP', '(no llega)')}\n")
    return texto, 200, {"Content-Type": "text/plain; charset=utf-8"}


print("Aplicacion en http://127.0.0.1:8000  (Ctrl+C para parar)")
serve(app, host="127.0.0.1", port=8000)