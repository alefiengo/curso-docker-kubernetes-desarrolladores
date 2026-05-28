# Lab 04: Volúmenes y Persistencia

## Objetivo

Agregar un volumen nombrado a un stack con base de datos PostgreSQL, insertar datos, recrear el stack completo y verificar que los datos persisten entre reinicios.

## Requisitos

- Haber completado los labs 01, 02 y 03 de esta sesión.
- Docker y Docker Compose v2 funcionando.

## Paso a paso

### Parte 1: stack con base de datos y volumen

**1. Crear el directorio de trabajo:**

```bash
mkdir -p ~/labs/lab05-03-volumenes && cd ~/labs/lab05-03-volumenes
```

**2. Crear el `compose.yaml` con volumen nombrado:**

```bash
cat > compose.yaml << 'EOF'
services:
  db:
    image: postgres:16.9-alpine
    environment:
      POSTGRES_USER: usuario
      POSTGRES_PASSWORD: secreto
      POSTGRES_DB: tienda
    volumes:
      - datos-postgres:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U usuario -d tienda"]
      interval: 5s
      timeout: 3s
      retries: 10

  api:
    image: node:22-alpine
    working_dir: /app
    command: node server.js
    environment:
      - PGHOST=db
      - PGUSER=usuario
      - PGPASSWORD=secreto
      - PGDATABASE=tienda
    volumes:
      - ./app:/app
    ports:
      - "3000:3000"
    depends_on:
      db:
        condition: service_healthy

volumes:
  datos-postgres:
EOF
```

Puntos clave:
- `datos-postgres:/var/lib/postgresql/data` monta el volumen nombrado en el directorio de datos de PostgreSQL.
- El `healthcheck` espera a que PostgreSQL acepte conexiones antes de arrancar la API.
- `depends_on` con `condition: service_healthy` garantiza que la API no arranca hasta que el healthcheck pase.

**3. Crear el directorio de la aplicación:**

```bash
mkdir -p app
```

**4. Crear el servidor Node.js:**

```bash
cat > app/server.js << 'EOF'
const http = require('http');
const { Client } = require('pg');

const client = new Client();
client.connect().catch(err => {
  console.error('Error conectando a PostgreSQL:', err.message);
  process.exit(1);
});

async function ensureTable() {
  await client.query(`
    CREATE TABLE IF NOT EXISTS productos (
      id SERIAL PRIMARY KEY,
      nombre TEXT NOT NULL,
      precio NUMERIC(10,2)
    )
  `);
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'GET' && req.url === '/productos') {
    const result = await client.query('SELECT * FROM productos ORDER BY id');
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(result.rows, null, 2) + '\n');
    return;
  }

  if (req.method === 'POST' && req.url === '/productos') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', async () => {
      const { nombre, precio } = JSON.parse(body);
      const result = await client.query(
        'INSERT INTO productos (nombre, precio) VALUES ($1, $2) RETURNING *',
        [nombre, precio]
      );
      res.writeHead(201, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(result.rows[0]) + '\n');
    });
    return;
  }

  res.writeHead(404);
  res.end('Not found\n');
});

ensureTable()
  .then(() => server.listen(3000, () => console.log('API en puerto 3000')))
  .catch(err => { console.error(err); process.exit(1); });
EOF
```

**5. Crear el `package.json` de la aplicación:**

```bash
cat > app/package.json << 'EOF'
{
  "name": "lab05-api",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "pg": "8.13.3"
  }
}
EOF
```

**6. Instalar las dependencias de la API:**

La aplicación usa `pg` (cliente de PostgreSQL para Node.js). Las instalas dentro del contenedor para que queden en el directorio `app/node_modules` montado por bind mount:

```bash
docker run --rm -v "$PWD/app":/app -w /app node:22-alpine npm install
```

Este comando crea `app/node_modules` y `app/package-lock.json` en tu directorio local.

### Parte 2: primera ejecución y datos iniciales

**7. Arrancar el stack:**

```bash
docker compose up -d
docker compose ps
```

Espera a que `db` llegue al estado `healthy` antes de que `api` arranque. Puedes seguir el proceso con:

```bash
docker compose logs -f db
```

Interrumpe con `Ctrl+C` cuando veas que PostgreSQL acepta conexiones.

**8. Verificar que la API responde:**

```bash
curl http://localhost:3000/productos
```

Devuelve un array vacío `[]` porque la tabla acaba de crearse.

**9. Insertar productos:**

```bash
curl -X POST http://localhost:3000/productos \
  -H "Content-Type: application/json" \
  -d '{"nombre": "Teclado", "precio": 45.99}'

curl -X POST http://localhost:3000/productos \
  -H "Content-Type: application/json" \
  -d '{"nombre": "Mouse", "precio": 19.50}'

curl -X POST http://localhost:3000/productos \
  -H "Content-Type: application/json" \
  -d '{"nombre": "Monitor", "precio": 249.00}'
```

**10. Verificar los datos en la API:**

```bash
curl http://localhost:3000/productos
```

Deberías ver los tres productos.

**11. Verificar los datos directamente en PostgreSQL:**

```bash
docker compose exec db psql -U usuario -d tienda -c "SELECT * FROM productos;"
```

### Parte 3: probar la persistencia

La prueba de persistencia consiste en bajar completamente el stack (destruyendo los contenedores), volver a levantarlo y verificar que los datos siguen ahí.

**12. Bajar el stack con `docker compose down`:**

```bash
docker compose down
```

`down` detiene y elimina los contenedores y la red. El volumen `datos-postgres` **no** se elimina.

**13. Verificar que el volumen sigue existiendo:**

```bash
docker volume ls | grep datos-postgres
```

El volumen persiste incluso sin contenedores que lo usen.

**14. Volver a arrancar el stack:**

```bash
docker compose up -d
docker compose ps
```

**15. Verificar que los datos persisten:**

```bash
curl http://localhost:3000/productos
```

Los tres productos siguen ahí. El volumen montó los datos de PostgreSQL exactamente donde los dejaste.

### Parte 4: comparar con y sin volumen

Para entender qué sucede sin volumen, prueba qué ocurriría si los datos estuvieran solo en el contenedor.

**16. Bajar el stack y eliminar el volumen:**

```bash
docker compose down -v
```

`-v` elimina además los volúmenes declarados en el `compose.yaml`.

**17. Confirmar que el volumen ya no existe:**

```bash
docker volume ls | grep datos-postgres
```

No aparece.

**18. Volver a levantar el stack y verificar:**

```bash
docker compose up -d
curl http://localhost:3000/productos
```

Devuelve `[]` — los datos desaparecieron porque el volumen fue eliminado.

### Parte 5: inspeccionar el volumen

**19. Ver información del volumen:**

Compose nombra los volúmenes con el prefijo del proyecto. El proyecto es el nombre del directorio de trabajo (`lab05-03-volumenes`):

```bash
docker volume ls | grep datos-postgres
docker volume inspect lab05-03-volumenes_datos-postgres
```

La salida muestra el `Mountpoint`: la ruta en el host donde Docker almacena los datos del volumen.

**20. Bind mount comparativo:**

Los bind mounts montan un directorio del host directamente. Son útiles para desarrollo porque reflejan cambios de código en tiempo real sin reconstruir:

```bash
cat > compose.override.yaml << 'EOF'
services:
  api:
    volumes:
      - ./app:/app
EOF
```

Este archivo `compose.override.yaml` se fusiona automáticamente con `compose.yaml` cuando ejecutas `docker compose up`. Permite sobrescribir configuración sin modificar el archivo principal.

## Validación

- [ ] `curl http://localhost:3000/productos` devuelve los tres productos insertados.
- [ ] `docker compose down && docker compose up -d` mantiene los productos en la base de datos.
- [ ] `docker volume ls` muestra el volumen `lab05-03-volumenes_datos-postgres` mientras el stack está abajo.
- [ ] `docker compose down -v` elimina el volumen y los datos se pierden en el siguiente arranque.
- [ ] `docker compose exec db psql -U usuario -d tienda -c "SELECT * FROM productos;"` devuelve los productos mientras el stack está arriba.
- [ ] `docker compose ps` muestra `db` con estado `healthy` y `api` con estado `running`.

## Limpieza

```bash
docker compose down -v
docker image prune -f
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| `api` se reinicia en bucle con `ECONNREFUSED` | La API arrancó antes de que PostgreSQL estuviera listo | Espera: con `condition: service_healthy` se detiene una vez pasa el healthcheck; si no, agrega el healthcheck a `db` |
| `pg_isready: command not found` en el healthcheck | La imagen base no incluye `pg_isready` | `postgres:16.9-alpine` sí lo incluye; si usas otra imagen, verifica con `docker run --rm postgres:16.9-alpine which pg_isready` |
| `node_modules` vacío dentro del contenedor | La instalación con `docker run` falló o usó una ruta diferente | Verifica que ejecutaste `npm install` con la ruta correcta al directorio `app/` |
| Los datos se pierden tras `docker compose down` sin `-v` | El volumen no está declarado en `compose.yaml` | Verifica que la clave `volumes:` está tanto en el servicio `db` como en la raíz del `compose.yaml` |
| `permission denied` al leer `app/node_modules` | `npm install` creó los archivos como root dentro del contenedor | Cambia la propiedad: `sudo chown -R $USER:$USER app/node_modules` |
| `FATAL: role "usuario" does not exist` | El contenedor ya existía con datos de una sesión anterior sin el usuario | Elimina el volumen con `docker compose down -v` y vuelve a arrancar |
