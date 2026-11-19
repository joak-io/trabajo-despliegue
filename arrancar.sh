#!/bin/bash
# Arranca el servidor entero. Desde la carpeta del trabajo, en Git Bash:  bash arrancar.sh
NGINX=/tmp/nginx
bash parar.sh
mkdir -p $NGINX/logs logs                                   # lo que estuviera arrancado, parado
ln -sfn "$PWD" /tmp/trabajo1
cp -r nginx/conf nginx/sitios $NGINX/     # la configuracion y los sitios, a nginx
cp /etc/nginx/mime.types $NGINX/conf/
chmod -R a+rX $NGINX
sudo nginx -p $NGINX/ -c conf/nginx.conf -t || exit 1
sudo nginx -p $NGINX/ -c conf/nginx.conf
python api/app.py > logs/api_salida.txt 2>&1 &
echo $! > api/pid.txt
python avisos/avisos.py > logs/avisos_salida.txt 2>&1 &
echo $! > avisos/pid.txt
sleep 3
bash pruebas.sh | tee pruebas.txt
