# Lab 03: Caché y Orden de Capas

## Objetivo

Medir el impacto del orden de instrucciones en el tiempo de rebuild de una imagen Node.js y demostrar que el orden correcto reduce el tiempo de builds sucesivos de forma significativa.

## Requisitos

- Docker funcionando.
- Conexión a internet para descargar `node:22-alpine`.
- Haber completado los labs 01 y 02 (comprensión del flujo de build).

## Paso a paso

### Parte 1: preparar la aplicación Node.js

Usarás una aplicación Express mínima. Node.js es ideal para demostrar la caché porque `npm ci` tarda varios segundos y se puede aislar en su propia capa.

**1. Crear el directorio de trabajo:**

```bash
mkdir -p ~/labs/lab04-03-cache && cd ~/labs/lab04-03-cache
```

**2. Crear el `package.json`:**

```bash
cat > package.json << 'EOF'
{
  "name": "lab04-cache",
  "version": "1.0.0",
  "description": "Lab de caché de capas",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "4.19.2"
  }
}
EOF
```

**3. Generar el archivo de bloqueo de dependencias:**

`npm ci` requiere un `package-lock.json` completo con todas las dependencias transitivas resueltas. Lo generas con `npm install`, que crea el archivo automáticamente a partir del `package.json`:

```bash
docker run --rm -v "$PWD":/app -w /app node:22-alpine npm install --package-lock-only
```

Este comando ejecuta `npm install --package-lock-only` dentro de un contenedor Node.js temporal: solo genera el `package-lock.json` sin crear `node_modules`, por lo que no deja archivos de root en tu directorio.

Verifica que el archivo fue generado:

```bash
ls -lh package-lock.json
```

**4. Crear la aplicación:**

```bash
cat > app.js << 'EOF'
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Sesion 4 - Cache de capas - v1\n');
});

app.listen(3000, () => {
  console.log('Servidor en puerto 3000');
});
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

### Parte 2: Dockerfile con orden subóptimo

En este Dockerfile el `COPY . .` va antes del `RUN npm ci`. Cada vez que editas cualquier archivo (incluido `app.js`), Docker invalida la capa del `COPY` y ejecuta `npm ci` de nuevo, aunque `package.json` no haya cambiado.

**6. Crear el Dockerfile con orden subóptimo:**

```bash
cat > Dockerfile.v1 << 'EOF'
FROM node:22-alpine
WORKDIR /app
COPY . .
RUN npm ci --omit=dev
EXPOSE 3000
CMD ["node", "app.js"]
EOF
```

**7. Primer build (descarga de imagen base y dependencias):**

```bash
time docker build -f Dockerfile.v1 --no-cache -t lab04-cache:v1 .
```

Anota el tiempo total. La mayor parte corresponde a la descarga de `node:22-alpine` y a `npm ci`.

**8. Simular una edición de código:**

```bash
sed -i 's/v1/v2/' app.js
```

**9. Rebuild con la edición:**

```bash
time docker build -f Dockerfile.v1 -t lab04-cache:v1 .
```

Observa en la salida del build qué capas dicen `CACHED` y cuáles se reconstruyen. Con el orden subóptimo, el `RUN npm ci` se ejecuta de nuevo aunque `package.json` no cambió.

### Parte 3: Dockerfile con orden óptimo

Separas el `COPY` de los archivos de dependencias (`package*.json`) del `COPY` del código. De esta forma, `npm ci` solo se invalida cuando cambia `package.json` o `package-lock.json`.

**10. Crear el Dockerfile con orden óptimo:**

```bash
cat > Dockerfile.v2 << 'EOF'
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 3000
CMD ["node", "app.js"]
EOF
```

**11. Primer build sin caché:**

```bash
time docker build -f Dockerfile.v2 --no-cache -t lab04-cache:v2 .
```

El tiempo será similar al primer build de `v1`: todo se construye desde cero.

**12. Simular otra edición de código:**

```bash
sed -i 's/v2/v3/' app.js
```

**13. Rebuild con la edición:**

```bash
time docker build -f Dockerfile.v2 -t lab04-cache:v2 .
```

Ahora el `COPY package*.json` y el `RUN npm ci` dicen `CACHED`. Solo el `COPY . .` y las instrucciones siguientes se reconstruyen. El rebuild debería terminar en menos de 3 segundos.

**14. Comparar los tiempos:**

```bash
echo "Build v1 (orden suboptimo) - reconstruye npm ci con cada cambio de codigo"
time docker build -f Dockerfile.v1 --no-cache -t lab04-cache:v1 .

echo ""
echo "Build v2 (orden optimo) - npm ci cacheado"
time docker build -f Dockerfile.v2 --no-cache -t lab04-cache:v2 .

# Editar el código para medir el rebuild
sed -i 's/v3/v4/' app.js

echo ""
echo "Rebuild v1 tras editar app.js"
time docker build -f Dockerfile.v1 -t lab04-cache:v1 .

echo ""
echo "Rebuild v2 tras editar app.js"
time docker build -f Dockerfile.v2 -t lab04-cache:v2 .
```

### Parte 4: multi-stage con caché óptima

En proyectos reales combinas multi-stage y orden de capas. La etapa de compilación también se beneficia del orden correcto.

**15. Crear un Dockerfile multi-stage con orden óptimo:**

```bash
cat > Dockerfile.v3 << 'EOF'
# Etapa 1: dependencias
FROM node:22-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

# Etapa 2: imagen final
FROM node:22-alpine
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
USER node
CMD ["node", "app.js"]
EOF
```

La etapa `deps` se cachea por separado. Si el código cambia pero `package.json` no, la etapa `deps` completa se reutiliza y solo se reconstruye la etapa final.

**16. Construir y verificar el usuario:**

```bash
docker build -f Dockerfile.v3 -t lab04-cache:v3 .
docker run --rm lab04-cache:v3 id
```

La imagen `node:22-alpine` incluye el usuario `node` (UID 1000) listo para usar.

**17. Verificar que la aplicación responde:**

```bash
docker run -d --name lab-cache -p 3000:3000 lab04-cache:v3
sleep 1
curl http://localhost:3000
```

**18. Ver el historial de capas comparando v1 y v3:**

```bash
echo "--- Capas de v1 ---"
docker image history lab04-cache:v1

echo ""
echo "--- Capas de v3 ---"
docker image history lab04-cache:v3
```

## Validación

- [ ] El rebuild de `v1` tras editar `app.js` ejecuta `npm ci` de nuevo (no hay `CACHED` en esa línea).
- [ ] El rebuild de `v2` tras editar `app.js` muestra `CACHED` en `RUN npm ci`.
- [ ] El tiempo de rebuild de `v2` es al menos 5 veces menor que el de `v1`.
- [ ] `docker run --rm lab04-cache:v3 id` devuelve un UID mayor que 0.
- [ ] `curl http://localhost:3000` devuelve la respuesta del servidor.
- [ ] `docker image ls lab04-cache` muestra las tres variantes con tamaños similares.

## Limpieza

```bash
docker rm -f lab-cache 2>/dev/null || true
docker image rm lab04-cache:v1 lab04-cache:v2 lab04-cache:v3 2>/dev/null || true
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| `npm ci` falla con `ENOENT package-lock.json` | El `package-lock.json` no existe o está incompleto | Ejecuta el paso 3 con `docker run --rm -v "$PWD":/app -w /app node:22-alpine npm install --package-lock-only` para generarlo |
| `Permission denied` al hacer `rm -rf` en el directorio del lab | `npm install` (sin `--package-lock-only`) crea `node_modules` como root dentro del contenedor | Elimina con el mismo contenedor: `docker run --rm -v "$PWD":/app -w /app node:22-alpine rm -rf node_modules` |
| `Cannot find module 'express'` al arrancar el contenedor | El `COPY . .` sobreescribió `node_modules` generados dentro del contenedor | Usa el patrón del `Dockerfile.v2`: copia `package*.json` primero, luego `npm ci`, luego el código |
| Los tiempos de rebuild son iguales en v1 y v2 | El caché fue limpiado entre los dos builds | Ejecuta ambos rebuilds seguidos sin `--no-cache`; el caché persiste solo si el daemon no fue reiniciado |
| `sed: command not found` | El sistema no tiene GNU sed | En macOS usa `sed -i '' 's/v1/v2/' app.js` (con comillas vacías después de `-i`) |
| `USER node` falla con `unknown user node` | La imagen base no incluye el usuario `node` | `node:22-alpine` lo incluye; si usas otra imagen base, crea el usuario manualmente con `adduser` |
