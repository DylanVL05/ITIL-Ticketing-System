#!/bin/bash

echo "🔧 Actualizando paquetes..."
sudo apt update && sudo apt upgrade -y

echo "📦 Instalando dependencias requeridas..."
sudo apt install -y curl git nginx apache2-utils

echo "🌐 Instalando Netdata desde repositorio oficial..."
bash <(curl -Ss https://my-netdata.io/kickstart-repository.sh)

echo "✅ Netdata instalado. Habilitando y arrancando el servicio..."
sudo systemctl enable netdata
sudo systemctl start netdata

echo "🛠️ Configurando NGINX como reverse proxy con autenticación..."

# Crear archivo de auth con usuario "admin"
echo "🧾 Creando archivo de usuarios..."
sudo htpasswd -c /etc/nginx/.htpasswd admin

# Crear archivo de configuración para Netdata en NGINX
cat <<EOF | sudo tee /etc/nginx/sites-available/netdata
server {
    listen 80;
    server_name _;

    location /netdata/ {
        proxy_pass http://localhost:19999/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_http_version 1.1;
        proxy_pass_request_headers on;

        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
}
EOF

# Enlazar la config
sudo ln -s /etc/nginx/sites-available/netdata /etc/nginx/sites-enabled/netdata

echo "🔁 Reiniciando NGINX..."
sudo systemctl restart nginx

echo "✅ Netdata ahora está disponible en: http://<TU_IP>/netdata"
echo "🔐 Protegido con usuario 'admin' y la contraseña que configuraste."
