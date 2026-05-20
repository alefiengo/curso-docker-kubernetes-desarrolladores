#!/usr/bin/env bash
set -euo pipefail

echo "Contenedores de la sesión"
docker ps -a --filter "name=lab-" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

echo
echo "Imágenes usadas en la sesión"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" \
  | awk 'NR == 1 || $1 == "hello-world" || $1 == "nginx" || $1 == "ubuntu"'

echo
echo "Uso de disco Docker"
docker system df
