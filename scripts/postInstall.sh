# #set env vars
# set -o allexport; source .env; set +o allexport;

#wait until the server is ready
echo "Waiting for software to be ready ..."
sleep 150s;


# Define the Nginx configuration file path
NGINX_CONF=/opt/elestio/nginx/conf.d/${SITES}.conf

# Define the socket.io location block configuration
SOCKET_IO_BLOCK='
    location /socket.io/ {
        proxy_pass http://172.17.0.1:9000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header Origin $scheme://$host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header x-frappe-site-name frontend;
        proxy_cache_bypass $http_upgrade;
    }
'

# Use awk to find the start of the location / { block and insert above it
awk -v block="$SOCKET_IO_BLOCK" '
    /location \/ {/ && in_server_block {
        print block
        in_server_block = 0
    }
    $0 ~ /listen 443 ssl http2;/ { in_server_block = 1 }
    { print }
' "$NGINX_CONF" > /tmp/nginx.conf.tmp && mv /tmp/nginx.conf.tmp "$NGINX_CONF"

echo "Nginx configuration updated with socket.io proxy settings for port 443."
