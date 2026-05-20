#!/usr/bin/env bash
set -euo pipefail

echo "Limpiando contenedores de la sesión 1..."

containers="$(docker ps -aq --filter "name=lab-")"

if [ -n "$containers" ]; then
  docker rm -f $containers
  echo "[OK] Contenedores lab-* eliminados."
else
  echo "No hay contenedores lab-* para eliminar."
fi

optional_containers="$(docker ps -aq --filter "name=mi-servidor")"

if [ -n "$optional_containers" ]; then
  docker rm -f $optional_containers
  echo "[OK] Contenedores mi-servidor* eliminados."
else
  echo "No hay contenedores mi-servidor* para eliminar."
fi

echo
echo "Estado final lab-*:"
docker ps -a --filter "name=lab-"

echo
echo "Estado final mi-servidor*:"
docker ps -a --filter "name=mi-servidor"
