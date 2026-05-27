# Referencia Rápida: Sesión 4 — Multi-stage Builds y Optimización

## Multi-stage build

```dockerfile
# Etapa de compilación
FROM golang:1.22-alpine AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /app/servidor .

# Etapa final
FROM alpine:3.21
COPY --from=builder /app/servidor /app/servidor
CMD ["/app/servidor"]
```

## Usuario no root (Alpine)

```dockerfile
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --chown=appuser:appgroup . .
USER appuser
```

## Usuario no root (Debian / Ubuntu)

```dockerfile
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
COPY --chown=appuser:appgroup . .
USER appuser
```

## Orden óptimo de capas (Node.js)

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./          # Cambia solo con dependencias nuevas
RUN npm ci --omit=dev          # Cacheado mientras package.json no cambie
COPY . .                       # Cambia con cada edición de código
USER node
CMD ["node", "app.js"]
```

## Orden óptimo de capas (Python)

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .        # Cambia solo con dependencias nuevas
RUN pip install --no-cache-dir -r requirements.txt
COPY . .                       # Cambia con cada edición de código
USER nobody
CMD ["python", "app.py"]
```

## Imágenes base por tamaño

| Base | Tamaño aprox. | Cuándo usarla |
|---|---|---|
| `ubuntu:24.04` | ~80 MB | Entornos de desarrollo con herramientas completas |
| `debian:bookworm-slim` | ~75 MB | Apps que necesitan `apt` |
| `node:22-alpine` | ~55 MB | Apps Node.js en producción |
| `python:3.12-slim` | ~45 MB | Apps Python en producción |
| `alpine:3.21` | ~7 MB | Base para binarios compilados |
| `scratch` | 0 MB | Binarios estáticos Go (`CGO_ENABLED=0`) |

## Comandos de build

```bash
# Build estándar
docker build -t nombre:tag .

# Build sin caché
docker build --no-cache -t nombre:tag .

# Build hasta una etapa específica
docker build --target builder -t nombre:debug .

# Ver tamaño de la imagen
docker image ls nombre:tag

# Ver capas y tamaños
docker image history nombre:tag
docker image history --format 'table {{.Size}}\t{{.CreatedBy}}' nombre:tag

# Medir tiempo de build
time docker build -t nombre:tag .
```

## Verificación de usuario y seguridad

```bash
# Usuario que corre el proceso
docker run --rm nombre:tag whoami
docker run --rm nombre:tag id

# Usuario configurado en la imagen
docker image inspect nombre:tag --format '{{.Config.User}}'

# Verificar que no hay shell ni herramientas extra en la imagen final
docker run --rm nombre:tag which sh   2>&1 || echo "no encontrado"
docker run --rm nombre:tag which bash 2>&1 || echo "no encontrado"
```

## CMD vs ENTRYPOINT en multi-stage

```dockerfile
# Patrón recomendado: ENTRYPOINT fijo + CMD con args por defecto
ENTRYPOINT ["./servidor"]
CMD ["--port", "8080"]

# Para override: docker run imagen --port 9090
```

## Señales y PID 1

```dockerfile
# Forma exec (recomendada): el proceso es PID 1, recibe SIGTERM correctamente
CMD ["node", "app.js"]

# Forma shell (evitar): /bin/sh es PID 1, el proceso no recibe señales
CMD node app.js
```

## Limpieza

```bash
# Eliminar imágenes de los labs
docker image rm lab04-app:single lab04-app:multistage \
  lab04-app:root lab04-app:noroot lab04-app:slim \
  lab04-cache:v1 lab04-cache:v2 lab04-cache:v3 \
  2>/dev/null || true

# Limpiar imágenes intermedias y sin tag
docker image prune -f
```
