# Sesión 5: Docker Compose, Redes y Volúmenes

## Objetivo

Orquestar una aplicación multi-servicio con Docker Compose definiendo servicios, redes personalizadas y volúmenes nombrados en un único archivo `compose.yaml`.

## Duración

2 horas.

## Materiales

- [Referencia rápida](referencia-rapida.md)
- [Desafío opcional](tareas/desafio-opcional.md)

## Laboratorios

| # | Nombre | Tema |
|---|---|---|
| [01](labs/01-redes-cli/README.md) | Redes con Docker CLI | Crear redes, conectar contenedores y verificar aislamiento con `docker network connect/disconnect` |
| [02](labs/02-compose-basico/README.md) | Compose básico | Definir y arrancar un stack de dos servicios con `compose.yaml` |
| [03](labs/03-redes/README.md) | Redes en Compose | Crear redes personalizadas y comprobar el DNS interno entre servicios |
| [04](labs/04-volumenes/README.md) | Volúmenes en Compose | Persistir datos de una base de datos con volúmenes nombrados y verificar la persistencia entre reinicios |

## Al finalizar esta sesión podrás

- Crear redes Docker con `docker network create` y conectar contenedores con `docker network connect/disconnect`.
- Explicar por qué dos contenedores en redes distintas no se comunican y cómo el DNS interno resuelve nombres.
- Escribir un `compose.yaml` con dos o más servicios interconectados.
- Usar `docker compose up`, `down`, `logs` y `exec` para operar el stack.
- Crear redes personalizadas en Compose para segmentar el tráfico entre servicios.
- Declarar volúmenes nombrados para que los datos persistan entre reinicios.
- Verificar que los datos de una base de datos sobreviven a `docker compose down` seguido de `docker compose up`.
- Inspeccionar redes y volúmenes con `docker network inspect` y `docker volume inspect`.

## Conceptos Clave

### Qué es Docker Compose

Docker Compose toma un archivo `compose.yaml` y crea todos los recursos declarados: contenedores, redes y volúmenes. En lugar de ejecutar varios `docker run` a mano con flags y nombres, defines el estado deseado una sola vez y Compose lo materializa.

El motor de Docker Compose está integrado en Docker como plugin desde la versión 20.10. El comando es `docker compose` (sin guion). El archivo preferido se llama `compose.yaml`.

### Anatomía de un compose.yaml

```yaml
services:
  api:
    image: node:22-alpine
    working_dir: /app
    command: node server.js
    ports:
      - "3000:3000"
    environment:
      - DB_HOST=db
    networks:
      - backend
    depends_on:
      - db

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: secreto
    volumes:
      - datos-db:/var/lib/postgresql/data
    networks:
      - backend

networks:
  backend:

volumes:
  datos-db:
```

Claves de la estructura:

- `services`: cada entrada es un contenedor. El nombre del servicio es también el hostname DNS dentro de las redes del stack.
- `networks`: redes declaradas. Si solo se nombran sin opciones, Compose las crea como `bridge`.
- `volumes`: volúmenes nombrados. Compose los crea si no existen.

La propiedad `version:` en la raíz del archivo está obsoleta. No la uses.

### Redes en Compose

Cuando arrancas un stack, Compose crea automáticamente una red `bridge` llamada `<proyecto>_default` y conecta todos los servicios a ella. Los servicios se resuelven por nombre: desde el contenedor `api` puedes hacer `ping db` y obtienes la IP del contenedor `db`.

Puedes declarar redes adicionales para segmentar servicios:

```yaml
networks:
  frontend:
  backend:
```

Un servicio conectado solo a `backend` no puede comunicarse directamente con uno conectado solo a `frontend`. Esto es útil para aislar la base de datos del acceso externo.

El DNS interno de Compose resuelve:
- `nombre-del-servicio` — hostname corto dentro de la misma red.
- `nombre-del-servicio.nombre-de-la-red` — hostname completo entre redes.

### Volúmenes nombrados

Los datos escritos dentro de un contenedor desaparecen cuando el contenedor se elimina. Un volumen nombrado persiste en el sistema de archivos del host gestionado por Docker y sobrevive a `docker compose down`.

```yaml
volumes:
  datos-db:
```

Esta declaración en la raíz del archivo es el equivalente de `docker volume create datos-db`. Compose lo crea la primera vez que arrancas el stack y no lo elimina con `docker compose down`. Para eliminar los volúmenes debes agregar la bandera `-v`:

```bash
docker compose down -v
```

La diferencia entre un volumen nombrado y un bind mount:

| | Volumen nombrado | Bind mount |
|---|---|---|
| Ruta en el host | Gestionada por Docker bajo `/var/lib/docker/volumes/` | Ruta explícita del host (`./datos:/var/lib/...`) |
| Portabilidad | Alta: funciona igual en cualquier entorno | Baja: depende de la estructura del host |
| Uso típico | Bases de datos, datos de aplicación | Código fuente en desarrollo |

### Comandos del ciclo de vida

```bash
docker compose up -d          # Arranca en segundo plano
docker compose down           # Detiene y elimina contenedores y redes
docker compose down -v        # Además elimina los volúmenes
docker compose ps             # Estado de los servicios
docker compose logs -f        # Logs en tiempo real
docker compose exec servicio comando  # Ejecuta un comando en el contenedor
docker compose restart servicio       # Reinicia un servicio
docker compose pull           # Descarga imágenes actualizadas
```

### depends_on y orden de arranque

`depends_on` le dice a Compose que arranque un servicio antes que otro, pero no espera a que la aplicación dentro esté lista, solo a que el contenedor haya iniciado. Si la base de datos tarda en aceptar conexiones, la API puede fallar en el primer intento.

La solución correcta es reintentos en el código de la aplicación o un `healthcheck` en el servicio de base de datos:

```yaml
db:
  image: postgres:16-alpine
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U postgres"]
    interval: 5s
    timeout: 3s
    retries: 5

api:
  depends_on:
    db:
      condition: service_healthy
```

Con `condition: service_healthy`, Compose espera a que el `healthcheck` pase antes de arrancar la API.

### Variables de entorno y archivos .env

Compose lee automáticamente un archivo `.env` en el mismo directorio si existe:

```bash
# .env
POSTGRES_PASSWORD=secreto
APP_PORT=3000
```

Y en el `compose.yaml`:

```yaml
services:
  db:
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
  api:
    ports:
      - "${APP_PORT}:3000"
```

El archivo `.env` no debe versionarse si contiene credenciales reales. Usa `.env.example` con valores de ejemplo para documentar las variables necesarias.

## Comandos de la Sesión

```bash
# Ciclo de vida del stack
docker compose up -d
docker compose down
docker compose down -v
docker compose restart

# Estado e inspección
docker compose ps
docker compose logs
docker compose logs -f nombre-servicio
docker compose top

# Ejecutar comandos en contenedores
docker compose exec nombre-servicio sh
docker compose exec nombre-servicio comando

# Construir imágenes definidas con build:
docker compose build
docker compose up --build

# Redes
docker network ls
docker network inspect nombre-red

# Volúmenes
docker volume ls
docker volume inspect nombre-volumen

# Limpiar todo del stack
docker compose down -v --rmi local
```

## Validación General

- [ ] `docker compose ps` muestra todos los servicios del stack con estado `running`.
- [ ] `docker compose exec api ping -c1 db` resuelve el hostname del servicio de base de datos.
- [ ] `docker compose down && docker compose up -d` mantiene los datos en el volumen nombrado.
- [ ] `docker network inspect` muestra los contenedores conectados a la red del stack.
- [ ] `docker volume inspect` muestra el punto de montaje del volumen de la base de datos.
- [ ] `docker compose logs api` muestra la salida del contenedor de la API.

## Limpieza

```bash
docker rm -f $(docker ps -aq --filter "name=lab05-") 2>/dev/null || true
docker network rm $(docker network ls -q --filter "name=lab05") 2>/dev/null || true
docker volume rm $(docker volume ls -q --filter "name=lab05") 2>/dev/null || true
docker image prune -f
```

Verifica:

```bash
docker ps -a --filter "name=lab05"
docker volume ls --filter "name=lab05"
docker network ls --filter "name=lab05"
```

## Desafío Opcional

Toma la aplicación Express del lab 03 de la sesión 4 y agrégale Redis para contar las visitas a la ruta `/`. Define el stack completo en un `compose.yaml` con redes segmentadas y un volumen para Redis.

Ver instrucciones completas en [tareas/desafio-opcional.md](tareas/desafio-opcional.md).

## Cierre

Antes de cerrar la sesión, verifica que puedes responder:

- [ ] ¿Cuál es la diferencia entre `docker compose down` y `docker compose down -v`?
- [ ] ¿Cómo resuelve DNS el nombre de un servicio desde otro contenedor del mismo stack?
- [ ] ¿Por qué `depends_on` no garantiza que la base de datos esté lista para aceptar conexiones?
- [ ] ¿Cuándo usarías un bind mount en lugar de un volumen nombrado?
- [ ] ¿Qué hace `docker compose exec` y en qué se diferencia de `docker exec`?
- [ ] ¿Cómo evitas versionar credenciales al usar variables de entorno en Compose?

## Preparación para la Siguiente Sesión

En la sesión 6 construirás un stack multi-servicio con API, base de datos, caché y gateway, y aplicarás escaneo de vulnerabilidades con Trivy. Asegúrate de que el stack de esta sesión levanta sin errores y de tener espacio en disco para descargar las imágenes de la sesión siguiente (`postgres:16.9-alpine`, `redis:7.4-alpine`).
