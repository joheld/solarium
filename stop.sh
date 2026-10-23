#!/usr/bin/env bash
# ==============================================================================
# Script de apagado para Solarium
# ==============================================================================
set -euo pipefail

PORT=5195
PID=$(lsof -ti :$PORT || true)

if [ -n "$PID" ]; then
    echo "🛑 Deteniendo servidor de Solarium (PID: $PID)..."
    kill -15 "$PID" 2>/dev/null || kill -9 "$PID" 2>/dev/null
    echo "✅ Servidor detenido correctamente."
else
    echo "ℹ️ No hay ningún servidor corriendo en el puerto $PORT."
fi
