# Manual del servidor web del Festival de Cine de Verano

Manual para que el cliente, u otra persona, pueda hacerse cargo del servidor sin preguntarnos.


Para ver este .MD en el formato correcto, porfavor hacer Ctrl + Shift + V

> Lo que va entre `<<...>>` hay que rellenarlo con los datos reales del equipo donde se monte.

---

## 1. Qué es y para qué cliente

Es el servidor web del **Festival de Cine de Verano**: cine al aire libre en plazas y parques de la ciudad. Incluye:

- La **web pública** con HTTPS: portada, programación y sedes.
- La **zona de abonados** (`/socios/`), con usuario y contraseña.
- Las **descargas**: los carteles de las películas.
- La **API de las películas**, detrás de nginx.
- El **servicio de avisos** (cambios por lluvia), que los abonados ven y publican desde la web.
- La **web pública en un contenedor**, probada en la nube (GitHub Codespaces).

### El contenido del cliente

| Página | Qué dice |
|---|---|
| `index.html` | Portada: qué es el festival, fechas, proyecciones al aire libre |
| `programacion.html` | Qué película se proyecta cada noche y a qué hora |
| `sedes.html` | Dónde se proyecta (Plaza Mayor, Parque del Río, patio del colegio) y cómo llegar |

Además: `estilo.css`, `404.html` (*Esa pelicula no esta en la cartelera*), `50x.html` (*Se ha apagado el proyector*) y `socios/index.html`.

**La API** (`/api/peliculas` y `/api/peliculas/<n>`): 1. Cinema Paradiso · 2. El verano de Kikujiro · 3. Los Goonies.

**Los abonados**

| Usuario | Contraseña |
|---|---|
| lucia | palomitas |
| pablo | butaca |
| irene | pantalla |

**Los avisos**: "Por lluvia, la proyeccion del viernes pasa al polideportivo" y "La sesion del domingo se retrasa a las 23:00 por tormenta".

**Las descargas**: `cartel_cinema_paradiso.txt`, `cartel_kikujiro.txt`, `cartel_goonies.txt`.

### Qué hay instalado y dónde

| Programa | Versión | Dónde | Cómo se instaló |
|---|---|---|---|
| nginx | `<<./nginx -v>>` | `C:\daw\nginx` | Descargado de nginx.org y descomprimido (prácticas de clase) |
| Python | `<<python --version>>` | El del sistema | Instalador de python.org |
| Flask | 3.1.3 | Librería de Python | `pip install -r api/requirements.txt` |
| waitress | 3.0.2 | Librería de Python | `pip install -r api/requirements.txt` |
| OpenSSL y Git Bash | `<<openssl version>>` | Git for Windows | Instalador de Git |

### La carpeta: `C:\daw\trabajo1`

```
nginx/conf/      nginx.conf, usuarios.txt y el certificado (publica.crt; la .key no se entrega)
nginx/sitios/    publica/ (las páginas) y descargas/ (los carteles)
api/             app.py, requirements.txt y cliente.py
avisos/          avisos.py
logs/            analizar.py y analisis.txt
contenedor/      Dockerfile, default.conf, sitio/ y contenedor.txt
pruebas.sh, pruebas.txt, arrancar.sh, parar.sh, concurrencia.txt y este manual
```

La configuración y las páginas **se escriben en `trabajo1`** y se copian a `C:\daw\nginx` (lo hace `arrancar.sh`).

---

## 2. Cómo se arranca y se para

Todo desde `C:\daw\trabajo1`, en **Git Bash**.

### La primera vez en un equipo

1. Copiar la carpeta a `C:\daw\trabajo1` (o `git clone https://github.com/joak-io/trabajo-despliegue.git trabajo1` desde `C:\daw`).
2. Instalar las librerías: `pip install -r api/requirements.txt`.
3. Crear el certificado (la `.key` no viaja con el trabajo):

```bash
openssl req -x509 -nodes -newkey rsa:2048 -days 365 -subj "//CN=publica.localhost" -keyout nginx/conf/publica.key -out nginx/conf/publica.crt
```

### Arrancar: `bash arrancar.sh`

```bash
#!/bin/bash
bash parar.sh                                   # lo que estuviera arrancado, parado
cp -r nginx/conf nginx/sitios /c/daw/nginx/     # la configuracion y los sitios, a nginx
cd /c/daw/nginx
./nginx -t || exit 1                            # si la config tiene un error, para aqui
./nginx &
cd - > /dev/null
python api/app.py > logs/api_salida.txt 2>&1 &
echo $! > api/pid.txt
python avisos/avisos.py > logs/avisos_salida.txt 2>&1 &
echo $! > avisos/pid.txt
sleep 3
bash pruebas.sh | tee pruebas.txt
```

- `&` deja cada programa de fondo y `$!` es su número de proceso, que se guarda en `pid.txt`.
- Al final pasa todas las pruebas y las guarda en `pruebas.txt`: todo tiene que salir en **OK**.
- Si se para en `./nginx -t`, la configuración tiene un error: esa línea dice cuál. También `C:\daw\nginx\logs\error.log`.

### Parar: `bash parar.sh`

```bash
#!/bin/bash
kill $(cat api/pid.txt avisos/pid.txt 2> /dev/null) 2> /dev/null
rm -f api/pid.txt avisos/pid.txt
(cd /c/daw/nginx && ./nginx -s stop 2> /dev/null)
sleep 1
```

Para **solo** nuestra API y nuestros avisos, por su número de proceso. **Nunca** `taskkill //IM python.exe`: pararía todos los Python del equipo.

### Tras cambiar la configuración a mano

```bash
cp -r nginx/conf nginx/sitios /c/daw/nginx/
cd /c/daw/nginx && ./nginx -t && ./nginx -s reload
```

---

## 3. El mapa

| Dirección | Qué sirve | Quién entra |
|---|---|---|
| `publica.localhost:8080` | Redirección **301** a HTTPS | Todos |
| `publica.localhost:8443` | La web pública, con su log (`publica.log`) | Todos |
| ` /socios/` | Zona de abonados | lucia, pablo, irene (usuario y contraseña) |
| ` /admin/` | Estado de nginx (`stub_status`) | Solo este equipo (127.0.0.1) |
| ` /oficina/` | Zona de la oficina | Solo la red 192.168.1.0/24 (desde aquí, 403) |
| ` /api/` | La API, que está en 127.0.0.1:8000 | Todos (cuerpo de 1 KB como máximo) |
| ` /avisos` | Los avisos (los da el 8001) | Solo los abonados |
| `descargas.localhost:8080` | El listado de los carteles | Todos |
| Otro nombre en el 8080 | **444**: no contesta | Nadie |
| `127.0.0.1:8000` | La API (Flask + waitress, 4 hilos) | Solo este equipo |
| `127.0.0.1:8001` | El servicio de avisos, sin nginx | Solo este equipo |

Todo escucha en `127.0.0.1`: desde fuera del equipo no se llega.

---

## 4. El certificado

Es **autofirmado** (lo hemos hecho nosotros), por eso el navegador avisa y curl necesita `-k`.

**Cuándo caduca:**

```bash
openssl x509 -in nginx/conf/publica.crt -noout -enddate
```

Resultado: `<<notAfter=Nov 16 14:53:44 2027 GMT>>` (365 días desde que se creó).

**Cómo se hace otro**: la orden de la sección 2 ("La primera vez"), y después copiar y recargar (ver Procedimientos).

---

## 5. Los logs, el análisis y la concurrencia

### Los logs

| Log | Dónde | Qué guarda |
|---|---|---|
| `publica.log` | `C:\daw\nginx\logs\` | Cada petición a la web, formato `detallado` |
| `descargas.log` | `C:\daw\nginx\logs\` | Cada petición a las descargas |
| `error.log` | `C:\daw\nginx\logs\` | Errores de nginx (nivel `warn`) |
| `avisos.log` | `trabajo1/logs/` | Cada petición al servicio de avisos |
| `api_salida.txt`, `avisos_salida.txt` | `trabajo1/logs/` | Lo que escriben la API y los avisos al arrancar |

El formato `detallado` guarda también lo que tarda cada petición:

```
fecha | ip | GET /ruta | 200 | 512 bytes | 0.003 s
```

### El análisis

Con el analizador del ejemplo 8, ampliado con el tiempo medio, la más lenta y el % de errores:

```bash
python logs/analizar.py /c/daw/nginx/logs/publica.log > logs/analisis.txt
```

Resultado (`logs/analisis.txt`):

- Tiempo medio: `<<0.002 >>` s
- La más lenta: `<</api/quien>>` (`<<0.032 >>` s) — es de la API: nginx tiene que esperar a otro programa.
- Errores (400 o más): `<<43.8>>` % — son casi todos **provocados por las pruebas** (401 sin usuario, 403 de la oficina, 404, 413), no fallos reales.

### La concurrencia

```bash
python api/cliente.py 4 | tail -1 > concurrencia.txt
python api/cliente.py 8 | tail -1 >> concurrencia.txt
```

`cliente.py` lanza N peticiones a la vez a `/api/lenta`, que tarda 2 s.

| Peticiones a la vez | Tiempo total |
|---|---|
| 4 | `<<~2>>` s |
| 8 | `<<~4>>` s |

**Por qué el doble**: waitress atiende con **4 hilos**. Con 4 peticiones, cada una va a un hilo y acaban todas a los 2 s. Con 8, las primeras 4 ocupan los hilos y las otras 4 **esperan** a que quede uno libre: otros 2 s.

---

## 6. Una petición por dentro

```bash
curl -sk -v https://publica.localhost:8443/api/peliculas/2
```
### Salida:

```bash
  Host publica.localhost:8443 was resolved.
  IPv6: ::1
  IPv4: 127.0.0.1
    Trying [::1]:8443...
    Trying 127.0.0.1:8443...
  schannel: disabled automatic use of client certificate
  ALPN: curl offers http/1.1
  ALPN: server accepted http/1.1
  Established connection to publica.localhost (127.0.0.1 port 8443) from 127.0.0.1 port 53556 
  using HTTP/1.x
  GET /api/peliculas/2 HTTP/1.1
  Host: publica.localhost:8443
  User-Agent: curl/8.21.0
  Accept: /
 
  Request completely sent off
  schannel: remote party requests renegotiation
  schannel: renegotiating SSL/TLS connection
  schannel: SSL/TLS connection renegotiated
  schannel: remote party requests renegotiation
  schannel: renegotiating SSL/TLS connection
  schannel: SSL/TLS connection renegotiated
  < HTTP/1.1 200 OK
  < Server: nginx
  < Date: Mon, 16 Nov 2026 15:20:40 GMT
  < Content-Type: application/json
  < Content-Length: 43
  < Connection: keep-alive
  < Strict-Transport-Security: max-age=31536000
  < X-Content-Type-Options: nosniff
  < X-Frame-Options: SAMEORIGIN
  < 
  {"n":2,"pelicula":"El verano de Kikujiro"}
  Connection #0 to host publica.localhost:8443 left intact
```
- Las líneas con `>` son **lo que manda curl**:
  - el **método**: `GET` (pedir algo);
  - la **ruta**: `/api/peliculas/2`;
  - **Host**: `publica.localhost:8443`, que es como nginx sabe a qué `server` va.
- Las líneas con `<` son **la respuesta**:
  - el **código**: `200 OK`;
  - las cabeceras: `Content-Type: application/json`, las de seguridad y `Server: nginx` sin versión;
  - y el cuerpo: `{"n": 2, "pelicula": "El verano de Kikujiro"}`.
- Por dentro: nginx recibe la petición por HTTPS, la `location /api/` la pasa a la API (`proxy_pass http://api`, el 127.0.0.1:8000) contándole la IP real (`X-Real-IP`), y devuelve lo que la API contesta.

### Los códigos que usamos

| Código | Qué significa | Dónde sale |
|---|---|---|
| 301 | Movido para siempre | Del 8080 en claro al 8443 con HTTPS |
| 401 | Falta usuario o es incorrecto | `/socios/` y `/avisos` sin usuario |
| 403 | Prohibido | `/oficina/` desde fuera de su red |
| 404 | No existe | Una página o una película que no existe |
| 413 | Demasiado grande | Más de 1 KB a la API |
| 502 | nginx no llega a lo de detrás | La API o los avisos parados |

---

## 7. Cómo lo hemos probado

`pruebas.sh` hace una prueba por cada cosa que pide el cliente; `arrancar.sh` la pasa al final y guarda el resultado en `pruebas.txt`.

| Prueba | Qué se pide | Tiene que salir | Resultado |
|---|---|---|---|
| En claro, manda a HTTPS | `http://publica.localhost:8080/` | 301 | OK |
| Portada | `/` | 200 | OK |
| Programación | `/programacion.html` | 200 | OK |
| Sedes | `/sedes.html` | 200 | OK |
| Estilos | `/estilo.css` | 200 | OK |
| Página inexistente | `/pagina-inexistente.html` | 404 | OK |
| El 404 es el nuestro | La misma | "Esa pelicula no esta en la cartelera" | OK |
| gzip | `/` con `Accept-Encoding: gzip` | `Content-Encoding: gzip` | OK |
| nosniff | `/` | `X-Content-Type-Options: nosniff` | OK |
| X-Frame-Options | `/` | `X-Frame-Options: SAMEORIGIN` | OK |
| HSTS | `/` | `Strict-Transport-Security` | OK |
| Server sin versión | `/` | `Server: nginx` sin `/versión` | OK |
| Abonados, sin usuario | `/socios/` | 401 | OK |
| Abonados, con usuario | `/socios/` con `lucia:palomitas` | 200 | OK |
| Abonados, contraseña mala | `/socios/` con `lucia:mala` | 401 | OK |
| Admin | `/admin/` | 200 | OK |
| Admin dice Active connections | `/admin/` | "Active connections" | OK |
| Oficina | `/oficina/` | 403 | OK |
| Descargas | `descargas.localhost:8080/` | 200 | OK |
| Descargas dice Index of | La misma | "Index of" | OK |
| Otro nombre | `otro.localhost:8080/` | 000 (444) | OK |
| API, la lista | `/api/peliculas` | 200 | OK |
| API, una | `/api/peliculas/2` | 200 | OK |
| API, una que no existe | `/api/peliculas/9` | 404 | OK |
| API, X-Real-IP | `/api/quien` | "127.0.0.1" | OK |
| API, más de 1 KB | POST de 2000 bytes | 413 | OK |
| Avisos, la lista | `127.0.0.1:8001/avisos` | 200 | OK |
| Avisos, uno nuevo | POST con `-d` | 201 | OK |
| Avisos, ruta que no existe | `127.0.0.1:8001/otra` | 404 | OK |
| Avisos web, sin usuario | `/avisos` | 401 | OK |
| Avisos web, con usuario | `/avisos` con `lucia:palomitas` | 200 | OK |
| Avisos web, uno nuevo | POST a `/avisos` con usuario | 201 | OK |

### El 502

A mano, porque hay que parar la API:

```bash
kill $(cat api/pid.txt)
curl -sk https://publica.localhost:8443/api/peliculas
```

Sale **nuestra** página `50x.html` (*Se ha apagado el proyector*). Tarda unos 2 s: Windows espera antes de rendirse. Después, `bash arrancar.sh` para dejarlo todo arriba.

### El contenedor

La web pública empaquetada con Docker (`nginx:alpine` + nuestras páginas + `default.conf` con `server_tokens off`, el log `detallado` y nuestras páginas de error), probada en GitHub Codespaces:

```bash
cd contenedor
docker build -t mi-web .
docker run -d -p 8080:80 --name web mi-web
curl -I http://localhost:8080/              # 200, Server: nginx a secas
curl http://localhost:8080/noexiste         # nuestra 404
{ docker ps; curl -sI http://localhost:8080/; docker logs web 2>/dev/null | grep ' | '; } > contenedor.txt
docker stop web
docker rm web
```

`contenedor/contenedor.txt` tiene el contenedor corriendo, el 200 con `Server: nginx` sin versión y las líneas del log con el formato `detallado`. Solo lleva la **web pública**: la zona de abonados, la API y los avisos siguen en el servidor principal.

---

## 8. Los procedimientos

### Añadir un abonado

```bash
echo "nuevo:$(openssl passwd -apr1 clave)" >> nginx/conf/usuarios.txt
cp -r nginx/conf /c/daw/nginx/
cd /c/daw/nginx && ./nginx -t && ./nginx -s reload
```

Con `>>` (añadir), **nunca** `>`: borraría a los demás. Sirve para `/socios/` y para `/avisos`.

### Publicar un aviso desde la web

```bash
curl -sk -u lucia:palomitas -d "Hoy se proyecta en el polideportivo" https://publica.localhost:8443/avisos
```

Responde **201** con el aviso nuevo. Sin tildes ni ñ (se ven mal en Windows). Los avisos se guardan en memoria: si se reinicia el servicio, vuelven los dos iniciales.

### Renovar el certificado

```bash
openssl req -x509 -nodes -newkey rsa:2048 -days 365 -subj "//CN=publica.localhost" -keyout nginx/conf/publica.key -out nginx/conf/publica.crt
cp -r nginx/conf /c/daw/nginx/
cd /c/daw/nginx && ./nginx -t && ./nginx -s reload
```

Comprobar la nueva fecha con `openssl x509 -in nginx/conf/publica.crt -noout -enddate`.

### Restaurar la configuración

Si alguien rompe el `nginx.conf` (o cualquier fichero), se recupera la última versión buena del repositorio:

```bash
git checkout nginx/conf/nginx.conf      # o: git checkout .   para todo
bash arrancar.sh
```

Sin git: volver a copiar la carpeta del `.zip` entregado y `bash arrancar.sh`.

---

## 9. La arquitectura

```
   cliente (navegador / curl)
            │  HTTP 8080 / HTTPS 8443
            ▼
   ┌──────────────────────────────┐
   │ nginx                        │  HTTPS, redirección, zonas, usuarios,
   │                              │  páginas estáticas, descargas, logs
   └─────┬───────────────┬────────┘
         │ proxy /api/   │ proxy /avisos
         ▼               ▼
   API Flask+waitress   servicio de avisos
   127.0.0.1:8000       127.0.0.1:8001
```

- **Capa de entrada**: nginx. Es lo único que da la cara: cifra, decide quién entra y sirve los ficheros.
- **Capa de aplicación**: la API y los avisos, que solo escuchan en `127.0.0.1` y solo les habla nginx.
- **Dónde corre**: todo en **la misma máquina** (Windows), por eso todo va a `127.0.0.1`.

**En varias máquinas o en la nube:**

- nginx en una máquina con IP pública y un **certificado de verdad** (Let's Encrypt), sin el `-k`.
- La API y los avisos en otras máquinas: en el `upstream` y el `proxy_pass`, su IP en lugar de `127.0.0.1`, y que escuchen en su red interna.
- Un **firewall** que solo deje entrar a nginx por 80/443, y a la API y los avisos solo desde nginx.
- Varias copias de la API en el `upstream` para repartir la carga (más hilos o más máquinas).
- Cada pieza en su **contenedor**: el del paso 14 es el primero (la web pública), que ya se levanta igual en cualquier sitio con Docker.

---

## 10. Decisiones, problemas, recomendaciones y quién ha hecho qué

### Decisiones

- La zona se llama `/socios/` en la ruta, como en la guía (así encajan la config y las pruebas), aunque para el cliente sean **abonados**.
- Avisos y frases de las páginas de error **sin tildes ni ñ**: en Git Bash y Windows se ven mal y las pruebas las buscan con `grep`.
- Cada uno escribió sus bloques de nginx en un fichero aparte (`api.conf.txt`, `avisos.conf.txt`) y uno solo los juntó en el `nginx.conf`, para no pisarnos.
- Trabajo en un **repositorio privado de GitHub**, con `.gitignore` para la `.key`, los `pid.txt` y los logs.
- `/avisos` con `location =` (exacta), porque el servicio solo entiende esa ruta.

### Problemas y cómo los resolvimos

| Problema | Causa | Solución |
|---|---|---|
| Todos los abonados daban 401 | `usuarios.txt` con saltos de línea de Windows (CRLF) | `sed -i 's/\r$//'` y un `.gitattributes` con `eol=lf` |
| Las descargas daban 404 | Los carteles no se subieron al repositorio | Crearlos de nuevo y subirlos |
| El contenedor se caía al arrancar | `default.conf` con un bloque `http {}`, y `log_format` dentro del `server` | En `conf.d` no va `http` (ya está dentro); `log_format` arriba del todo |
| `git push` sin rama remota | Rama local `master`, en GitHub `main` | `git branch -M main` y `git push -u origin main` |
| Algunas pruebas fallaban con el servidor bien | Texto o URL mal puestos en `pruebas.sh` | Corregir las líneas; `grep` distingue mayúsculas |
| `<<...>>` | `<<...>>` | `<<...>>` |

### Recomendaciones

**De uso**
- Arrancar y parar siempre con `arrancar.sh` y `parar.sh`, y mirar `pruebas.txt` después.
- `./nginx -t` antes de cada recarga; si algo falla, `error.log`.
- Revisar la caducidad del certificado cada pocos meses.

**De seguridad**
- Contraseñas largas y distintas para cada abonado (las de ahora son de ejemplo).
- No compartir nunca la `.key` ni subirla a ningún sitio.
- En producción, certificado de una autoridad (Let's Encrypt) y el servidor detrás de un firewall.
- Mantener `server_tokens off` y las cabeceras de seguridad.
- Guardar los avisos en un fichero o una base de datos: ahora se pierden al reiniciar.

### Quién ha hecho qué

| Persona | Bloque | Pasos | Del manual |
|---|---|---|---|
| Rubén | A: nginx y la web | 3 a 7: páginas, `nginx.conf` común y 444, certificado y HTTPS, zonas, descargas. Junta el `nginx.conf` | Mapa, certificado, añadir abonado, renovar certificado |
| Daniel | B: los programas en Python | 8 a 10: API, `location /api/`, avisos y `location = /avisos`; 13: concurrencia | API, avisos, concurrencia, una petición por dentro, publicar un aviso |
| Joaquín | C: scripts, pruebas, nube y manual | 1 y 2; 11: `arrancar.sh` y `parar.sh`; 12: `pruebas.sh`; 13: análisis del log; 14: contenedor | Estructura, arranque, logs, pruebas, restaurar, arquitectura, decisiones. Junta el manual |
