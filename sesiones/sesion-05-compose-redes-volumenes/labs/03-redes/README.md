# Lab 03: Redes en Compose

## Objetivo

Crear redes personalizadas en un `compose.yaml`, conectar servicios a redes específicas y verificar que el aislamiento de red funciona: los servicios en redes distintas no se comunican directamente.

## Requisitos

- Haber completado los labs 01 y 02 de esta sesión.
- Docker y Docker Compose v2 funcionando.

## Paso a paso

### Parte 1: preparar el stack segmentado

En este lab usarás tres servicios: un frontend (nginx), una API (Node.js) y una base de datos (Redis). El objetivo es que:

- El frontend pueda hablar con la API.
- La API pueda hablar con Redis.
- El frontend NO pueda hablar directamente con Redis.

Esta segmentación se logra conectando cada servicio solo a las redes que necesita.

**1. Crear el directorio de trabajo:**

```bash
mkdir -p ~/labs/lab05-02-redes && cd ~/labs/lab05-02-redes
```

**2. Crear la API Node.js:**

```bash
cat > api.js << 'EOF'
const express = require('express');
const redis = require('redis');

const app = express();
const client = redis.createClient({ url: 'redis://cache:6379' });
client.connect().catch(console.error);

app.get('/status', async (req, res) => {
  try {
    await client.ping();
    res.json({ api: 'ok', cache: 'ok' });
  } catch (err) {
    res.json({ api: 'ok', cache: 'error' });
  }
});

app.listen(3000, () => console.log('API en puerto 3000'));
EOF
```

**3. Crear el `package.json` de la API:**

```bash
cat > package.json << 'EOF'
{
  "name": "lab05-api",
  "version": "1.0.0",
  "main": "api.js",
  "scripts": { "start": "node api.js" },
  "dependencies": {
    "express": "4.19.2",
    "redis": "4.7.0"
  }
}
EOF
```

**4. Generar el lockfile de dependencias:**

```bash
docker run --rm -v "$PWD":/app -w /app node:22-alpine npm install --package-lock-only
```

**5. Crear el `Dockerfile` de la API:**

```bash
cat > Dockerfile << 'EOF'
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 3000
CMD ["node", "api.js"]
EOF
```

**6. Crear el `.dockerignore`:**

```bash
cat > .dockerignore << 'EOF'
node_modules
*.log
.git
EOF
```

### Parte 2: compose.yaml con redes segmentadas

**7. Crear el `compose.yaml` con tres servicios y dos redes:**

```bash
cat > compose.yaml << 'EOF'
services:
  frontend:
    image: nginx:1.27-alpine
    ports:
      - "8080:80"
    networks:
      - publica

  api:
    build: .
    networks:
      - publica
      - privada
    depends_on:
      - cache

  cache:
    image: redis:7.4-alpine
    networks:
      - privada

networks:
  publica:
  privada:
EOF
```

La topología de red resultante es:

```
internet
   |
nginx (publica)
   |
  api (publica + privada)
   |
redis (privada)
```

Nginx y Redis no comparten ninguna red, por lo que no pueden comunicarse directamente.

**8. Arrancar el stack:**

```bash
docker compose up --build -d
docker compose ps
```

### Parte 3: verificar el DNS interno

**9. Verificar que la API resuelve el nombre de Redis:**

```bash
docker compose exec api ping -c2 cache
```

Debes ver respuestas de la IP del contenedor `cache`. El nombre `cache` se resuelve porque ambos servicios están en la red `privada`.

**10. Verificar que la API resuelve el nombre del frontend:**

```bash
docker compose exec api ping -c2 frontend
```

Funciona porque ambos servicios comparten la red `publica`.

**11. Verificar que el frontend NO puede resolver Redis:**

```bash
docker compose exec frontend ping -c2 cache 2>&1 || echo "No alcanzable — correcto"
```

La resolución falla porque `frontend` no está conectado a la red `privada` donde vive `cache`.

### Parte 4: inspeccionar las redes

**12. Listar las redes del stack:**

```bash
docker network ls | grep lab05
```

Verás dos redes con prefijo del proyecto: `lab05-02-redes_publica` y `lab05-02-redes_privada`.

**13. Inspeccionar la red privada:**

```bash
docker network inspect lab05-02-redes_privada
```

En la sección `Containers` aparecen solo `api` y `cache`. El frontend no está.

**14. Inspeccionar la red pública:**

```bash
docker network inspect lab05-02-redes_publica
```

En la sección `Containers` aparecen solo `frontend` y `api`.

**15. Ver las redes a las que está conectada la API:**

```bash
docker inspect $(docker compose ps -q api) --format '{{json .NetworkSettings.Networks}}' | python3 -m json.tool 2>/dev/null || \
docker inspect $(docker compose ps -q api) --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}'
```

La API aparece conectada a dos redes: `publica` y `privada`.

### Parte 5: nombre de proyecto personalizado

Por defecto Compose usa el nombre del directorio como nombre de proyecto. Puedes cambiarlo con la opción `-p`:

**16. Bajar el stack actual:**

```bash
docker compose down
```

**17. Arrancar con nombre de proyecto explícito:**

```bash
docker compose -p sesion05-redes up -d
docker network ls | grep sesion05
```

Las redes ahora tienen el prefijo `sesion05-redes_`.

**18. Bajar con el mismo nombre de proyecto:**

```bash
docker compose -p sesion05-redes down
```

## Validación

- [ ] `docker compose exec api ping -c2 cache` resuelve la IP de Redis.
- [ ] `docker compose exec api ping -c2 frontend` resuelve la IP de nginx.
- [ ] `docker compose exec frontend ping -c2 cache` falla con "Name or service not known".
- [ ] `docker network inspect lab05-02-redes_privada` muestra solo `api` y `cache` en `Containers`.
- [ ] `docker network inspect lab05-02-redes_publica` muestra solo `frontend` y `api` en `Containers`.
- [ ] `docker compose ps` muestra los tres servicios con estado `running`.

## Limpieza

```bash
docker compose down
docker compose -p sesion05-redes down 2>/dev/null || true
docker image rm lab05-02-redes-api 2>/dev/null || true
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| `ping: cache: Name or service not known` al hacer ping desde la API | El servicio `api` no está conectado a la red `privada` en el `compose.yaml` | Verifica que `api` tenga `privada` en su lista de `networks:` |
| `ping: frontend: Name or service not known` al hacer ping desde la API | El servicio `api` no está conectado a la red `publica` | Verifica que `api` tenga `publica` en su lista de `networks:` |
| `frontend` sí puede hacer ping a `cache` | Los servicios están en la misma red o el `compose.yaml` no tiene la segmentación correcta | Revisa que `frontend` tenga solo `publica` y `cache` tenga solo `privada` |
| `docker network ls` no muestra las redes del lab | El stack no está corriendo | Ejecuta `docker compose up -d` antes de inspeccionar |
| `docker compose exec frontend ping` devuelve `ping: command not found` | La imagen `nginx:1.27-alpine` tiene `ping` bajo el paquete `iputils-ping` en alpine | Usa `docker compose exec frontend wget -q -O- http://api:3000/status` como alternativa para verificar conectividad |
