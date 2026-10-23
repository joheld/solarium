#!/usr/bin/env bash
# ==============================================================================
# Launcher para Escritorio - Solarium
# Desacoplado de terminal POSIX con inmunidad SIGHUP
# Prioriza http://127.0.0.1:5195 para habilitar Secure Context y Geolocation en el navegador
# ==============================================================================
set -euo pipefail

PORT=5195
HOST="127.0.0.1"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/solarium_server.log"

# Asegurar que el servidor local esté activo en el puerto 5195
if ! lsof -i :$PORT >/dev/null 2>&1; then
    nohup python3 -m http.server "$PORT" --bind "$HOST" </dev/null >"$LOG_FILE" 2>&1 &
    sleep 0.4
fi

# Abrir en el navegador preferente usando el servidor local (Secure Context)
if lsof -i :$PORT >/dev/null 2>&1; then
    open "http://${HOST}:${PORT}"
else
    open "$DIR/index.html"
fi
