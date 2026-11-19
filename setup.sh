#!/bin/bash
set -e


# Dependencias de la API de Daniel
pip install -r api/requirements.txt

# Config de nginx de Rubén
sudo cp nginx/nginx.conf /etc/nginx/nginx.conf
sudo cp -r web/* /var/www/html/

# Comprobar y arrancar nginx (en codespaces no hay systemctl)
sudo nginx -t
sudo service nginx start

# Arrancar la API en segundo plano
nohup python3 api/app.py > api.log 2>&1 &

echo "Todo arrancado"
