# Desafío Opcional: Sesión 5 — Docker Compose, Redes y Volúmenes

Esta práctica es para reforzar lo visto después de clase. No se entrega y no es requisito para la siguiente sesión.

## Objetivo

Tomar la aplicación Express del lab 03 de la sesión 4 y convertirla en un stack completo con Redis para contar visitas, redes segmentadas y un volumen para persistir el contador entre reinicios.

## Criterios mínimos

1. El stack tiene al menos dos servicios: la API Express y Redis.
2. El `compose.yaml` no usa la propiedad `version:`.
3. Redis tiene un volumen nombrado para persistir los datos.
4. Los servicios están conectados a una red personalizada (no solo la red `default`).
5. La ruta `/` de la API muestra cuántas veces ha sido visitada, usando Redis como almacén del contador.
6. El contador persiste tras `docker compose down` y `docker compose up -d`.
7. El `compose.yaml` usa un `healthcheck` en Redis y `depends_on` con `condition: service_healthy`.
8. Existe un `.env.example` con las variables de entorno necesarias.

## Forma de verificar

```bash
# Arrancar el stack
docker compose up -d

# Verificar el contador
curl http://localhost:3000
curl http://localhost:3000
curl http://localhost:3000

# Debe mostrar algo como: "Visitas: 3"

# Bajar y subir sin eliminar volúmenes
docker compose down
docker compose up -d
curl http://localhost:3000

# Debe mostrar: "Visitas: 4"

# Verificar el volumen
docker volume inspect <nombre-del-volumen>

# Limpiar
docker compose down -v
```

## Estructura sugerida del proyecto

```
lab05-desafio/
  app.js
  package.json
  Dockerfile
  .dockerignore
  compose.yaml
  .env.example
```

## Pistas técnicas

### Conectar Node.js a Redis con el cliente redis v4

```javascript
const redis = require('redis');
const client = redis.createClient({ url: 'redis://cache:6379' });
await client.connect();

// Incrementar un contador
const visitas = await client.incr('visitas');
```

### Healthcheck para Redis

```yaml
cache:
  image: redis:7.4-alpine
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 5s
    timeout: 3s
    retries: 5
```

### Volumen para Redis

Redis persiste datos en `/data` cuando se configura con `--appendonly yes`:

```yaml
cache:
  image: redis:7.4-alpine
  command: redis-server --appendonly yes
  volumes:
    - datos-redis:/data
```

## Puntos adicionales para profundizar

Si completaste los criterios mínimos y quieres explorar más:

- Agrega una ruta `/reset` que ponga el contador en cero.
- Agrega una tercera ruta `/stats` que devuelva el conteo en JSON: `{"visitas": 42}`.
- Agrega `restart: unless-stopped` a los servicios para que reinicien automáticamente si el host se reinicia.
- Usa un archivo `.env` para parametrizar el puerto de la API y el nombre de la clave de Redis.
- Publica la imagen de la API en Docker Hub con el tag `tu-usuario/lab05-api:1.0` y modifica el `compose.yaml` para usar la imagen publicada en lugar de `build: .`.
