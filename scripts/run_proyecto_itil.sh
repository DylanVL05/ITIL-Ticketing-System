#!/bin/bash
# Script: run_proyecto_itil.sh

# Se debe primero instalar el entorno para conseguir las variables o tokens necesarios en automatizar tickets 

echo "📦 Instalando Zabbix Server..."
bash instalar_zabbix.sh

echo "⏳ Espera unos segundos antes de correr la automatización..."
sleep 15

echo "🤖 Ejecutando prueba de automatización ITIL..."
bash automatizar_tickets.sh

echo "🎉 Proyecto ITIL automatizado con Zabbix y GLPI listo."
