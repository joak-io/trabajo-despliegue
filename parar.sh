#!/bin/bash
# Para el servidor entero. Desde la carpeta del trabajo:  bash parar.sh
NGINX=/tmp/nginx
kill $(cat api/pid.txt avisos/pid.txt 2> /dev/null) 2> /dev/null
rm -f api/pid.txt avisos/pid.txt
sudo nginx -p $NGINX/ -c conf/nginx.conf -s stop 2> /dev/null
sleep 1
