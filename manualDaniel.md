## 6. La API y los avisos

- **La API (`api/app.py`):** Implementada en Python con Flask y servida mediante `waitress` (4 hilos por defecto) en `127.0.0.1:8000`. Sus dependencias se instalan con `pip install -r api/requirements.txt`. Expone las siguientes rutas:
    - `GET /api/estado`: comprobación de funcionamiento (`{"estado": "ok"}`).
    - `GET /api/peliculas`: devuelve el listado completo de películas del festival en JSON.
    - `GET /api/peliculas/<n>`: devuelve la película por número (del 1 al 3) o un error `404` en JSON si no existe.
    - `GET /api/lenta`: espera 2 segundos (`time.sleep(2)`) para simular una tarea pesada y medir la concurrencia.
    - `GET /api/quien` (ruta comodín): devuelve en texto plano la ruta solicitada, el `Host` y la cabecera `X-Real-IP` reenviada por nginx.
- **El servicio de avisos (`avisos/avisos.py`):** Servidor HTTP programado a mano en Python puro (`ThreadingHTTPServer`) escuchando en `127.0.0.1:8001`.
    - `GET /avisos`: devuelve la lista de avisos en JSON (`200`).
    - `POST /avisos`: lee el cuerpo de la petición, añade el aviso y devuelve `201`.
    - Registra cada petición en `logs/avisos.log` con IP origen, fecha/hora, método, ruta, código de estado y tamaño en bytes.
    - Al acceder por la web (`https://publica.localhost:8443/avisos`), nginx actúa como proxy inverso exigiendo autenticación básica (`Zona de abonados`).

## 8. La concurrencia y su porqué

Al ejecutar `api/cliente.py` contra `/api/lenta` (donde cada petición tarda 2 segundos):

- Con **4 peticiones simultáneas**, el tiempo total medido es de **2.10 s**.
- Con **8 peticiones simultáneas**, el tiempo total medido sube al doble: **4.14 s**.

**Por qué:** `waitress` atiende las peticiones con **4 hilos**. Con 4 peticiones a la vez, cada una entra en un hilo distinto y terminan todas en paralelo a los ~2 segundos. Con 8 peticiones, las primeras 4 ocupan todos los hilos disponibles y las 4 restantes esperan en cola hasta que se libere uno, sumando otros 2 segundos adicionales.

## 9. Una petición por dentro

Al lanzar `curl -sk -v https://publica.localhost:8443/api/peliculas/2`:

- **Líneas con `>` (petición enviada por `curl`):** Indican el método (`GET`), la ruta solicitada (`/api/peliculas/2`) y la cabecera `Host` (`publica.localhost:8443`).
- **Líneas con `<` (respuesta del servidor):** Muestran el código de estado (`HTTP/1.1 200 OK`), las cabeceras (`Content-Type: application/json`, las cabeceras de seguridad configuradas en nginx y `Server: nginx` sin número de versión) y el cuerpo JSON (`{"n": 2, "pelicula": "El verano de Kikujiro"}`).

_(Pega aquí la salida literal de `curl -sk -v https://publica.localhost:8443/api/peliculas/2` cuando lo ejecutes con nginx y la API arrancados)_

**Códigos de estado HTTP utilizados en el proyecto:**

| Código  | Significado       | Cuándo ocurre en nuestro servidor                                                                                             |
| :------ | :---------------- | :---------------------------------------------------------------------------------------------------------------------------- |
| **301** | Moved Permanently | Redirección automática de HTTP (`8080`) a HTTPS (`8443`).                                                                     |
| **401** | Unauthorized      | Acceso sin usuario o con contraseña errónea en `/socios/` o `/avisos`.                                                        |
| **403** | Forbidden         | Acceso denegado por IP al entrar en `/oficina/` (solo permitida la red `192.168.1.0/24`).                                     |
| **404** | Not Found         | Ruta web inexistente (`404.html`), película fuera de rango en `/api/peliculas/<n>` o ruta distinta de `/avisos` en el `8001`. |
| **413** | Content Too Large | Envío de un cuerpo mayor de 1 KB a `/api/` (`client_max_body_size 1k`).                                                       |
| **502** | Bad Gateway       | Nginx intenta conectar con la API (`8000`) o con avisos (`8001`) pero el servicio Python está parado.                         |

## 11. Procedimientos (Publicar un aviso desde la web)

Para publicar un aviso nuevo autenticado como abonado a través de nginx:

```bash
curl -sk -u lucia:palomitas -d "Cambio de sede por lluvia" [https://publica.localhost:8443/avisos](https://publica.localhost:8443/avisos)
```

## 13. Quién ha hecho qué (Bloque B — Daniel)

- **API en Flask (`api/app.py` y `api/requirements.txt`):** Rutas `/api/peliculas`, `/api/peliculas/<n>`, `/api/lenta` y `/api/quien` servidas con `waitress`.
- **Servicio de avisos (`avisos/avisos.py`):** Servidor multihilo hecho a mano en el puerto `8001` con soporte para `GET`, `POST` y registro en `logs/avisos.log`.
- **Bloques de configuración para nginx (`api.conf.txt` y `avisos.conf.txt`):** Proxy inverso para `/api/` (limitado a 1 KB) y `/avisos` (protegido con usuario de abonados).
- **Pruebas de concurrencia (`api/cliente.py` y `concurrencia.txt`) y redacción de estas secciones del manual.**
