#!/bin/bash
# Script: instalar_entorno.sh

echo "🔧 Actualizando sistema..."
sudo apt update && sudo apt upgrade -y

echo "🧱 Instalando Apache, MariaDB y PHP..."
sudo apt install apache2 mariadb-server -y
sudo apt install php php-mysql php-xml php-curl php-mbstring php-zip php-bz2 php-gd php-intl unzip wget -y

echo "🛠️ Configurando base de datos GLPI..."
sudo mysql -e "CREATE DATABASE glpidb;"
sudo mysql -e "CREATE USER 'glpiuser'@'localhost' IDENTIFIED BY 'GLPIstrong123';"
sudo mysql -e "GRANT ALL PRIVILEGES ON glpidb.* TO 'glpiuser'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "⬇️ Descargando GLPI..."
cd /var/www/html
sudo wget https://github.com/glpi-project/glpi/releases/download/10.0.14/glpi-10.0.14.tgz
sudo tar -xvzf glpi-10.0.14.tgz
sudo rm glpi-10.0.14.tgz
sudo chown -R www-data:www-data glpi

echo "🔐 Activando Apache y reiniciando servicios..."
sudo systemctl enable apache2
sudo systemctl restart apache2

echo "✅ Instalación lista. Accede desde tu navegador a: http://$(hostname -I | awk '{print $1}')/glpi"
echo "📌 Usuario inicial: glpi / glpi"
