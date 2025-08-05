#!/bin/bash
set -e

# Variables que puedes ajustar:
DB_ROOT_PASS="TuRootPass"
DB_ZABBIX_PASS="TuZabbixPass"
DB_HOST="localhost"

# 1. Actualizar sistema
sudo apt update && sudo apt upgrade -y

# 2. Instalar MySQL/MariaDB
sudo apt install -y mariadb-server mariadb-client

sudo systemctl enable --now mariadb

# 3. Asegurar instalación MySQL
sudo mysql_secure_installation <<EOF

Y
$DB_ROOT_PASS
$DB_ROOT_PASS
Y
Y
Y
Y
EOF

# 4. Crear base de datos y usuario Zabbix
sudo mysql -uroot -p"$DB_ROOT_PASS" <<EOF
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER 'zabbix'@'$DB_HOST' IDENTIFIED BY '$DB_ZABBIX_PASS';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'$DB_HOST';
SET GLOBAL log_bin_trust_function_creators = 1;
FLUSH PRIVILEGES;
EXIT;
EOF

# 5. Agregar repositorio Zabbix
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-1+ubuntu24.04_all.deb
sudo dpkg -i zabbix-release_7.0-1+ubuntu24.04_all.deb
sudo apt update

# 6. Instalar servidor, frontend PHP, scripts SQL, Apache y agente
sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-sql-scripts zabbix-apache-conf zabbix-agent

# 7. Importar esquema de base de datos
sudo zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | sudo mysql -u zabbix -p"$DB_ZABBIX_PASS" zabbix

# 8. Configurar zabbix_server.conf
sudo sed -i "s/^# DBHost=localhost/DBHost=$DB_HOST/" /etc/zabbix/zabbix_server.conf
sudo sed -i "s/^DBName=.*/DBName=zabbix/" /etc/zabbix/zabbix_server.conf
sudo sed -i "s/^DBUser=.*/DBUser=zabbix/" /etc/zabbix/zabbix_server.conf
sudo sed -i "s/^# DBPassword=.*/DBPassword=$DB_ZABBIX_PASS/" /etc/zabbix/zabbix_server.conf

# 9. Configurar PHP en Apache (ajuste según tu zona horaria y requerimientos)
sudo sed -i "s/^;\s*date.timezone =.*/date.timezone = UTC/" /etc/zabbix/apache.conf

# 10. Reiniciar y habilitar servicios
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2

echo "Instalación completada."
echo "Ahora visita http://tu-servidor/zabbix para completar la configuración web."
