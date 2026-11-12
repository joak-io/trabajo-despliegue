#!/bin/bash
# Arranca el servidor entero. Desde la carpeta del trabajo, en Git Bash:  bash arrancar.sh
bash parar.sh                                   # lo que estuviera arrancado, parado
cp -r nginx/conf nginx/sitios /c/daw/nginx/     # la configuracion y los sitios, a nginx
cd /c/daw/nginx
./nginx -t || exit 1
./nginx &
cd - > /dev/null
python api/app.py > logs/api_salida.txt 2>&1 &
echo $! > api/pid.txt
python avisos/avisos.py > logs/avisos_salida.txt 2>&1 &
echo $! > avisos/pid.txt
sleep 3
bash pruebas.sh | tee pruebas.txt
