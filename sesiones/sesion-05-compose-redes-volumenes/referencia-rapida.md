# Referencia Rápida: Sesión 5 — Docker Compose, Redes y Volúmenes

## Ciclo de vida del stack

```bash
docker compose up -d                   # Arranca todos los servicios en segundo plano
docker compose up --build -d           # Reconstruye imágenes y arranca
docker compose down                    # Detiene y elimina contenedores y redes
docker compose down -v                 # También elimina volúmenes declarados
docker compose stop                    # Detiene sin eliminar
docker compose start                   # Arranca contenedores detenidos
docker compose restart nombre          # Reinicia un servicio específico
docker compose pull                    # Descarga versiones actualizadas de imágenes
```

## Inspección del stack

```bash
docker compose ps                      # Estado de los servicios
docker compose logs                    # Logs de todos los servicios
docker compose logs -f nombre          # Logs en tiempo real de un servicio
docker compose top                     # Procesos dentro de cada contenedor
docker compose config                  # Muestra el compose.yaml resuelto
docker compose events                  # Eventos del stack en tiempo real
```

## Ejecutar comandos en contenedores

```bash
docker compose exec nombre sh          # Shell interactivo
docker compose exec nombre comando     # Ejecutar un comando
docker compose run --rm nombre comando # Contenedor nuevo y efímero para un comando
```

## Redes

```bash
docker network ls                              # Listar redes
docker network inspect nombre-red             # Detalles de una red
docker network inspect nombre --format '{{range .Containers}}{{.Name}} {{end}}'
```

## Volúmenes

```bash
docker volume ls                               # Listar volúmenes
docker volume inspect nombre-volumen          # Detalles de un volumen
docker volume rm nombre-volumen               # Eliminar un volumen (solo si no está en uso)
docker volume prune                            # Eliminar volúmenes sin usar
```

## Estructura mínima de compose.yaml

```yaml
services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DB_HOST=db
    networks:
      - backend
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16.9-alpine
    environment:
      POSTGRES_PASSWORD: secreto
    volumes:
      - datos-db:/var/lib/postgresql/data
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
      retries: 10

networks:
  backend:

volumes:
  datos-db:
```

## Redes personalizadas para segmentación

```yaml
services:
  frontend:
    image: nginx:1.27-alpine
    networks:
      - publica

  api:
    build: .
    networks:
      - publica
      - privada

  db:
    image: postgres:16.9-alpine
    networks:
      - privada

networks:
  publica:
  privada:
```

`frontend` y `db` no comparten red: no se pueden comunicar directamente.

## Variables de entorno con archivo .env

```bash
# .env  (no versionar si tiene credenciales reales)
POSTGRES_PASSWORD=secreto
APP_PORT=3000
```

```yaml
# compose.yaml
services:
  db:
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
  api:
    ports:
      - "${APP_PORT}:3000"
```

## Volúmenes: nombrado vs bind mount

| | Volumen nombrado | Bind mount |
|---|---|---|
| Sintaxis | `datos-db:/var/lib/postgresql/data` | `./datos:/var/lib/postgresql/data` |
| Gestionado por | Docker | Tú (ruta del host) |
| Portabilidad | Alta | Baja |
| Uso típico | Producción, bases de datos | Desarrollo, código fuente |

## Imagen base recomendada por servicio

| Servicio | Imagen |
|---|---|
| API Node.js | `node:22-alpine` |
| PostgreSQL | `postgres:16.9-alpine` |
| Redis | `redis:7.4-alpine` |
| Frontend (nginx) | `nginx:1.27-alpine` |

## Healthcheck para PostgreSQL

```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U usuario -d basedatos"]
  interval: 5s
  timeout: 3s
  retries: 10
```

## depends_on con condición de salud

```yaml
api:
  depends_on:
    db:
      condition: service_healthy
```

Sin `condition: service_healthy`, Compose solo espera a que el contenedor inicie, no a que la aplicación dentro esté lista.
