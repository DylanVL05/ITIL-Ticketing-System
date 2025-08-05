#!/bin/bash

# CONFIGURACIÓN
APP_TOKEN=""
GLPI_API=""
LOGIN="glpi"
PASSWORD="glpi"
INTERVALO=60  # segundos entre chequeos
INTERFAZ_NET="eth0" # interfaz de red

# UMBRALES (ajustables)
CPU_UMBRAL=80       # %
RAM_UMBRAL=85       # %
TEMP_UMBRAL=75      # °C
NET_UMBRAL=50000000 # 50 MB/s (en bytes)

# Ruta de log (opcional)
LOG_FILE="/var/log/monitor_glpi.log"
exec >> "$LOG_FILE" 2>&1

# Obtener SESSION_TOKEN
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

# Función para crear ticket
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

# Reintentar ticket si GLPI está abajo
reintentar_crear_ticket() {
  local nombre="$1"
  local contenido="$2"
  local prioridad="$3"
  local categoria="$4"
  local intentos=0
  local max_intentos=30

  until curl -s -X POST "$GLPI_API/ticket" \
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
    }" | jq -e '.id' > /dev/null; do
    echo "⚠️ GLPI inaccesible. Reintentando creación de ticket... ($((++intentos)))"
    sleep 10
    if (( intentos >= max_intentos )); then
      echo "❌ No se pudo crear el ticket después de $max_intentos intentos."
      return 1
    fi
  done

  echo "📨 Ticket generado tras reintentos: $nombre"
}

# Bucle principal
while true; do
  echo "🔍 Ejecutando chequeo de infraestructura: $(date)"

  # === CPU ===
  cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
  cpu_int=${cpu_usage%.*}
  if (( cpu_int > CPU_UMBRAL )); then
    crear_ticket "Alta carga de CPU" "Uso actual: $cpu_int%" 4 2
  fi

  # === RAM ===
  ram_usage=$(free | awk '/Mem:/ {printf("%.0f", $3/$2 * 100)}')
  if (( ram_usage > RAM_UMBRAL )); then
    crear_ticket "Consumo excesivo de RAM" "RAM usada: $ram_usage%" 4 3
  fi

  # === Temperatura ===
  if command -v sensors &> /dev/null; then
    temp=$(sensors | grep -oP 'Package id 0:\s+\+?\K[0-9]+(?=\.\d+°C)')
    if [[ ! -z "$temp" && "$temp" -gt "$TEMP_UMBRAL" ]]; then
      crear_ticket "Temperatura crítica de CPU" "CPU a ${temp}°C" 5 4
    fi
  fi

  # === RED ===
  if [[ -e /sys/class/net/$INTERFAZ_NET/statistics/rx_bytes ]]; then
    net_inicial=$(cat /sys/class/net/$INTERFAZ_NET/statistics/rx_bytes)
    sleep 1
    net_final=$(cat /sys/class/net/$INTERFAZ_NET/statistics/rx_bytes)
    net_total=$((net_final - net_inicial))
    if (( net_total > NET_UMBRAL )); then
      crear_ticket "Alto tráfico de red" "Entrada detectada: $((net_total/1024/1024)) MB/s" 3 5
    fi
  fi

  # === Servicios ===
  for svc in apache2 mariadb ssh; do
    if ! systemctl is-active --quiet $svc; then
      if [[ "$svc" == "apache2" ]]; then
        echo "⚠️ Apache2 detectado como caído, GLPI podría estar fuera de línea."
        obtener_session_token  # intentar renovar sesión por si GLPI cayó
        reintentar_crear_ticket "Servicio caído: apache2" "GLPI está inaccesible. apache2 no está activo." 5 1
      else
        crear_ticket "Servicio caído: $svc" "El servicio $svc no está activo." 5 1
      fi
    fi
  done

  echo "🕒 Esperando $INTERVALO segundos antes del siguiente chequeo..."
  sleep $INTERVALO
done
