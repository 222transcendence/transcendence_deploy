#!/bin/sh
mkdir -p /etc/nginx/ssl
if [ ! -f /etc/nginx/ssl/localhost.crt ]; then
    echo "Generating self-signed SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/localhost.key \
        -out /etc/nginx/ssl/localhost.crt \
        -subj "/C=KR/ST=Gyeongsan/L=Gyeongsan/O=42Gyeongsan/OU=ft_transcendence/CN=localhost"
fi
echo "Starting nginx..."
exec nginx -g "daemon off;"
