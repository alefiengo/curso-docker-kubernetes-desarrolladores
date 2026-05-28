# Lab 02: Compose Básico

## Objetivo

Definir un stack de dos servicios (una API Node.js y una base de datos Redis) en un `compose.yaml` y operar el ciclo de vida completo con los comandos de Compose.

## Requisitos

- Haber completado el lab 01 de esta sesión (entiendes cómo funciona el DNS interno de Docker).
- Docker Compose v2 (`docker compose version` responde con v2).
- Haber completado los labs de la sesión 4 (sabes construir imágenes con `docker build`).

## Paso a paso

### Parte 1: preparar el proyecto

**1. Crear el directorio de trabajo:**

```bash
mkdir -p ~/labs/lab05-01-compose && cd ~/labs/lab05-01-compose
```

**2. Crear la aplicación Node.js:**

La aplicación responde en `/` con un saludo y en `/ping` con la respuesta de Redis.

```bash
cat > app.js << 'EOF'
const express = require('express');
const redis = require('redis');

const app = express();
const client = redis.createClient({ url: 'redis://cache:6379' });

client.connect().catch(console.error);

app.get('/', (req, res) => {
  res.send('Sesion 5 - Compose basico\n');
});

app.get('/ping', async (req, res) => {
  try {
    const pong = await client.ping();
    res.send(`Redis responde: ${pong}\n`);
  } catch (err) {
    res.status(503).send(`Redis no disponible: ${err.message}\n`);
  }
});

app.listen(3000, () => console.log('Servidor en puerto 3000'));
EOF
```

**3. Crear el `package.json`:**

```bash
cat > package.json << 'EOF'
{
  "name": "lab05-compose",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": { "start": "node app.js" },
  "dependencies": {
    "express": "4.19.2",
    "redis": "4.7.0"
  }
}
EOF
```

**4. Crear el `Dockerfile`:**

La imagen de la API usa el patrón de caché óptima de la sesión 4: primero `package*.json`, luego el código.

```bash
cat > Dockerfile << 'EOF'
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 3000
CMD ["node", "app.js"]
EOF
```

**5. Crear el `.dockerignore`:**

```bash
cat > .dockerignore << 'EOF'
node_modules
*.log
.git
EOF
```

### Parte 2: escribir el compose.yaml

**6. Crear el `compose.yaml`:**

```bash
cat > compose.yaml << 'EOF'
services:
  api:
    build: .
    ports:
      - "3000:3000"
    depends_on:
      - cache
    restart: on-failure

  cache:
    image: redis:7.4-alpine
    ports:
      - "6379:6379"
EOF
```

Puntos a notar:
- `build: .` le dice a Compose que construya la imagen desde el `Dockerfile` del directorio actual.
- `depends_on` garantiza que Redis arranque antes que la API (el contenedor, no necesariamente el servicio interno).
- `restart: on-failure` reinicia la API si falla al conectar con Redis en el primer intento.

### Parte 3: arrancar el stack

**7. Construir la imagen y arrancar en segundo plano:**

```bash
docker compose up --build -d
```

La primera vez descarga `redis:7.4-alpine` y construye la imagen de la API.

**8. Verificar que los servicios están corriendo:**

```bash
docker compose ps
```

Deberías ver dos servicios con estado `running`.

**9. Ver los logs de todos los servicios:**

```bash
docker compose logs
```

**10. Seguir los logs de la API en tiempo real:**

```bash
docker compose logs -f api
```

Interrumpe con `Ctrl+C`. Los contenedores siguen corriendo.

**11. Probar la API:**

```bash
curl http://localhost:3000
curl http://localhost:3000/ping
```

La primera ruta devuelve el saludo. La segunda confirma que Redis responde con `PONG`.

### Parte 4: inspeccionar el stack

**12. Ver los procesos dentro de cada contenedor:**

```bash
docker compose top
```

**13. Ejecutar un comando dentro del contenedor de Redis:**

```bash
docker compose exec cache redis-cli ping
```

Redis responde `PONG` directamente.

**14. Explorar la red por defecto del stack:**

Compose crea una red llamada `<proyecto>_default`. El nombre del proyecto es el nombre del directorio por defecto.

```bash
docker network ls | grep lab05
docker network inspect lab05-01-compose_default
```

Observa que tanto `api` como `cache` aparecen en la sección `Containers` de la red.

### Parte 5: ciclo de parada y arranque

**15. Detener el stack sin eliminar los recursos:**

```bash
docker compose stop
```

Los contenedores se detienen pero no se eliminan. `docker compose ps` los muestra como `exited`.

**16. Volver a arrancar sin reconstruir:**

```bash
docker compose start
curl http://localhost:3000/ping
```

**17. Bajar el stack y eliminar contenedores y redes:**

```bash
docker compose down
```

`docker compose ps` no mostrará nada. La imagen construida permanece en el sistema.

**18. Subir de nuevo y verificar que recrea los recursos:**

```bash
docker compose up -d
docker compose ps
curl http://localhost:3000
```

## Validación

- [ ] `docker compose ps` muestra `api` y `cache` con estado `running`.
- [ ] `curl http://localhost:3000` devuelve `Sesion 5 - Compose basico`.
- [ ] `curl http://localhost:3000/ping` devuelve `Redis responde: PONG`.
- [ ] `docker compose exec cache redis-cli ping` devuelve `PONG`.
- [ ] `docker network inspect lab05-01-compose_default` muestra los dos contenedores del stack.
- [ ] `docker compose down` elimina los contenedores y la red del stack.

## Limpieza

```bash
docker compose down
docker image rm lab05-01-compose-api 2>/dev/null || true
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| `Cannot connect to the Docker daemon` | Docker Desktop no está iniciado | Inicia Docker Desktop y espera a que esté listo |
| `Error response from daemon: driver failed programming external connectivity: port is already allocated` | El puerto 3000 o 6379 está ocupado por otro proceso | Cambia el puerto del host en `ports`: por ejemplo `"3001:3000"` |
| `api` arranca pero `/ping` devuelve error 503 | La API arrancó antes de que Redis estuviera listo | Espera unos segundos y reintenta; `restart: on-failure` reintenta automáticamente |
| `npm ci` falla con `ENOENT package-lock.json` | No existe `package-lock.json` en el directorio | Genera el lockfile: `docker run --rm -v "$PWD":/app -w /app node:22-alpine npm install --package-lock-only` |
| `Cannot find module 'redis'` | El build usó una imagen cacheada sin las dependencias | Reconstruye con `docker compose up --build` |
