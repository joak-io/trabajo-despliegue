#!/bin/bash
# Pruebas del servidor del Festival de Cine de Verano. Con todo arrancado:  bash pruebas.sh

P=https://publica.localhost:8443
D=http://descargas.localhost:8080
A=http://127.0.0.1:8001

# codigo URL: solo el codigo de la respuesta (-k: el certificado es nuestro)
codigo() { curl -sk -o /dev/null -w "%{http_code}" "$@"; }
# prueba NOMBRE LO_QUE_SALE LO_QUE_TIENE_QUE_SALIR
prueba() { [ "$2" = "$3" ] && echo "OK    $1" || echo "FALLO $1: $2 (tenia que ser $3)"; }

# cabecera NOMBRE TEXTO URL: que la respuesta traiga esa cabecera
cabecera() { curl -skI "${@:3}" | grep -qi "$2" && echo "OK    $1" || echo "FALLO $1"; }
# texto NOMBRE TEXTO URL: que la pagina diga ese texto
texto() { curl -sk "${@:3}" | grep -q "$2" && echo "OK    $1" || echo "FALLO $1"; }

echo "== Web publica =="
prueba   "en claro, manda a HTTPS"        "$(codigo http://publica.localhost:8080/)"        301
prueba   "portada"                        "$(codigo $P/)"                                   200
prueba   "programacion"                   "$(codigo $P/programacion.html)"                  200
prueba   "sedes"                          "$(codigo $P/sedes.html)"                         200
prueba   "estilos"                         "$(codigo $P/estilo.css)"                       200
prueba   "pagina inexistente"             "$(codigo $P/pagina-inexistente.html)"            404
texto    "el 404 es el nuestro"            "Esa pelicula no esta en la cartelera"               $P/pagina-inexistente.html

echo "== Cabeceras =="
cabecera "gzip"                         "Content-Encoding: gzip"                 -H "Accept-Encoding: gzip" $P/
cabecera "nosniff"                      "X-Content-Type-Options: nosniff"         $P/
cabecera "X-Frame-Options"              "X-frame-Options: SAMEORIGIN"             $P/
cabecera "HSTS"                         "Strict-Transport-Security"              $P/

! curl -skI $P/ | grep -q "Server: nginx/" && echo "OK    Server sin version" || echo "FALLO Server sin version"
# Este hace la peticion y valida que no sale la version del nginx


echo "== Zonas =="
prueba   "abonados, sin usuario"                           "$(codigo $P/socios/)"           401    
prueba   "abonados, con usuario"                           "$(codigo -u lucia:palomitas $P/socios/)"           200    
prueba   "abonados, con contrasena incorrecta"             "$(codigo -u lucia:mala $P/socios/)"                401    

prueba   "admin"                           "$(codigo $P/admin/)"                             200
texto    "admin dice Active connections"   "Active connections"                              $P/admin/
prueba   "oficina, desde aqui 403"         "$(codigo $P/oficina/)"                           403

echo "== Descargas =="
prueba "descargas"      "$(codigo $D/)"     200
texto  "descargas dice Index of"      "Index of"     $D/

echo "== API =="
prueba   "API, la lista"                   "$(codigo $P/api/peliculas)"                      200
prueba   "API, una"                        "$(codigo $P/api/peliculas/2)"                    200
prueba   "API, una que no existe"          "$(codigo $P/api/peliculas/9)"                    404
texto    "API, X-Real-IP lo pone nginx"    "127.0.0.1"                                       $P/api/quien
head -c 2000 /dev/zero | tr '\0' a > grande.txt
# Genera un documento muy pesado y lo guarda en grande.txt
prueba   "API, mas de 1 KB: 413"           "$(codigo --data-binary @grande.txt $P/api/peliculas)" 413
rm -f grande.txt

echo "== Avisos por la web =="
prueba   "avisos web, sin usuario"         "$(codigo $P/avisos)"                             401
prueba   "avisos web, con usuario"         "$(codigo -u lucia:palomitas $P/avisos)"          200
