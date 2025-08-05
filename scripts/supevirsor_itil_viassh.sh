#!/bin/bash

# CONFIGURACIÓN
APP_TOKEN=""
GLPI_API=""
LOGIN="glpi"
PASSWORD="glpi"
INTERVALO=60
INTERFAZ_NET="eth0"
REMOTE_HOST=""
SSH_KEY=""                                 #You must generate a key for ssh and run this like service with daemon 

# UMBRALES
CPU_UMBRAL=80
RAM_UMBRAL=85
TEMP_UMBRAL=75
NET_UMBRAL=50000000

# LOG
LOG_FILE="/var/log/monitor_glpi.log"
exec >> "$LOG_FILE" 2>&1

# Obtener session_token
obtener_session_token() {
  SESSION_TOKEN=$(curl -s -X POST "$GLPI_API/initSession" \
    -H "Content-Type: application/json" \
    -H "App-Token: $APP_TOKEN" \
    -d "{\"login\":\"$LOGIN\", \"password\":\"$PASSWORD\"}" | jq -r '.session_token')

  if [[ "$SESSION_TOKEN" == "null" || -z "$SESSION_TOKEN" ]]; then
    echo "❌ Error al obtener session_token."
    return 1
  fi
  return 0
}

obtener_session_token || exit 1

crear_ticket() {
  local nombre="$1"
  local contenido="$2"
  local prioridad="$3"
  local categoria="$4"

  curl -s -X POST "$GLPI_API/ticket" \
    -H "Content-Type: application/json" \
    -H "App-Token: $APP_TOKEN" \
    -H "Session-Token: $SESSION_TOKEN" \
    -d "{
      \"input\": {
        \"name\": \"$nombre\",
        \"content\": \"$contenido\",
        \"priority\": $prioridad,
        \"itilcategories_id\": $categoria
      }
    }" > /dev/null

  echo "📨 Ticket generado: $nombre"
}

while true; do
  echo "🔍 Monitoreando servidor remoto ($REMOTE_HOST) - $(date)"

  # === CPU ===
  cpu_usage=$(ssh -i $SSH_KEY -o BatchMode=yes -o StrictHostKeyChecking=no $REMOTE_HOST "top -bn1 | grep 'Cpu(s)' | awk '{print 100 - \$8}'")
  cpu_int=${cpu_usage%.*}
  if (( cpu_int > CPU_UMBRAL )); then
    crear_ticket "Alta carga de CPU" "Uso actual: $cpu_int% en $REMOTE_HOST" 4 2
  fi

  # === RAM ===
  ram_usage=$(ssh -i $SSH_KEY -o BatchMode=yes -o StrictHostKeyChecking=no $REMOTE_HOST "free | awk '/Mem:/ {printf(\"%.0f\", \$3/\$2 * 100)}'")
  if (( ram_usage > RAM_UMBRAL )); then
    crear_ticket "Consumo excesivo de RAM" "RAM usada: $ram_usage% en $REMOTE_HOST" 4 3
  fi

  # === TEMP ===
  temp=$(ssh -i $SSH_KEY -o BatchMode=yes -o StrictHostKeyChecking=no $REMOTE_HOST "sensors 2>/dev/null | grep -oP 'Package id 0:\\s+\\+?\\K[0-9]+(?=\\.\\d+°C)'")
  if [[ ! -z "$temp" && "$temp" -gt "$TEMP_UMBRAL" ]]; then
    crear_ticket "Temperatura crítica de CPU" "Temp: ${temp}°C en $REMOTE_HOST" 5 4
  fi

  # === RED ===
  net_inicial=$(ssh -i $SSH_KEY -o BatchMode=yes -o StrictHostKeyChecking=no $REMOTE_HOST "cat /sys/class/net/$INTERFAZ_NET/statistics/rx_bytes")
  sleep 1
  net_final=$(ssh -i $SSH_KEY -o BatchMode=yes -o StrictHostKeyChecking=no $REMOTE_HOST "cat /sys/class/net/$INTERFAZ_NET/statistics/rx_bytes")
  net_total=$((net_final - net_inicial))
  if (( net_total > NET_UMBRAL )); then
    crear_ticket "Alto tráfico de red" "Entrada: $((net_total/1024/1024)) MB/s en $REMOTE_HOST" 3 5
  fi

  echo "⏳ Esperando $INTERVALO segundos..."
  sleep $INTERVALO
done
