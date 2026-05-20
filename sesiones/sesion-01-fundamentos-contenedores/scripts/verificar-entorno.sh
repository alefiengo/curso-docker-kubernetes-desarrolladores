#!/usr/bin/env bash
set -euo pipefail

echo "Verificando Docker..."

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] Docker no está instalado o no está en PATH."
  exit 1
fi

docker --version

if ! docker info >/dev/null 2>&1; then
  echo "[ERROR] Docker no responde. Inicia Docker Desktop o el servicio Docker."
  exit 1
fi

echo "[OK] Docker está listo para la sesión 1."
