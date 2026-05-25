# Lab 02: Build Context y .dockerignore

## Objetivo

Comprender qué es el build context, medir su impacto en el tiempo y tamaño del build, y usar `.dockerignore` para excluir archivos innecesarios.

## Requisitos

- Docker funcionando (`docker version` responde sin error).
- Haber completado el lab 01 o tener experiencia básica con `docker build`.

## Paso a paso

### 1. Crear el directorio de trabajo

```bash
mkdir -p ~/workspace/lab02-contexto
cd ~/workspace/lab02-contexto
```

### 2. Simular un proyecto con dependencias pesadas

En proyectos reales, `node_modules` puede tener cientos de megabytes. Vas a simularlo creando archivos de relleno para ver el efecto en el build context.

```bash
# Crear estructura de proyecto
mkdir -p node_modules/paquete-pesado
# Simular dependencias (10 MB de datos de relleno)
dd if=/dev/urandom bs=1M count=10 of=node_modules/paquete-pesado/binario.bin 2>/dev/null

# Crear el código fuente real (muy pequeño)
echo "console.log('app arrancando');" > app.js

# Crear un archivo .env con datos sensibles
echo "DB_PASSWORD=secreto123" > .env
echo "API_KEY=clave-privada" >> .env
```

### 3. Escribir un Dockerfile mínimo

```bash
cat > Dockerfile <<'EOF'
FROM node:22-alpine
WORKDIR /app
COPY app.js .
CMD ["node", "app.js"]
EOF
```

Este `Dockerfile` no necesita `node_modules` ni `.env`. Sin embargo, si no tienes `.dockerignore`, Docker los enviará al daemon de todas formas.

### 4. Build sin .dockerignore: medir el contexto

Construye con salida detallada para ver el tamaño del contexto:

```bash
docker build --progress=plain -t lab02-contexto:sin-ignore . 2>&1 | head -20
```

Observa la línea `transferring context`. Verás el tamaño total enviado al daemon, que incluye los 10 MB de relleno y el archivo `.env`.

### 5. Crear el .dockerignore

Excluye lo que no necesita el build:

```bash
cat > .dockerignore <<'EOF'
# Dependencias instaladas localmente (se instalan dentro de la imagen)
node_modules

# Variables de entorno y secretos
.env
.env.*

# Control de versiones
.git
.gitignore

# Logs y archivos temporales
*.log
npm-debug.log*
EOF
```

### 6. Build con .dockerignore: comparar el contexto

```bash
docker build --progress=plain -t lab02-contexto:con-ignore . 2>&1 | head -20
```

Compara la línea `transferring context` de ambos builds. El segundo debe mostrar un tamaño drásticamente menor porque `node_modules` queda excluido.

### 7. Verificar que .env no llegó a la imagen

Aunque el `Dockerfile` nunca hace `COPY .env`, enviar ese archivo al contexto es un riesgo: si alguien modifica el Dockerfile para incluirlo, queda en una capa de la imagen. Verificar que no está accesible:

```bash
docker run --rm lab02-contexto:con-ignore ls -la /app
```

Solo debes ver `app.js`.

### 8. Inspeccionar las imágenes construidas

```bash
docker image ls lab02-contexto
docker image history lab02-contexto:con-ignore
```

Ambas imágenes tienen el mismo contenido funcional. La diferencia estuvo en el tiempo de construcción y en los datos innecesarios que viajaron al daemon en la primera versión.

### 9. Explorar .dockerignore con patrones adicionales

Agrega exclusiones habituales y reconstruye para ver el efecto:

```bash
cat >> .dockerignore <<'EOF'

# Archivos de editor y sistema
.DS_Store
*.swp
Thumbs.db

# Tests (no necesarios en la imagen de producción)
**/*.test.js
EOF

docker build -t lab02-contexto:avanzado .
```

## Validación

- [ ] `docker build --progress=plain` sin `.dockerignore` muestra un contexto mayor a 10 MB.
- [ ] `docker build --progress=plain` con `.dockerignore` muestra un contexto menor a 1 MB.
- [ ] `docker run --rm lab02-contexto:con-ignore ls /app` solo muestra `app.js`, sin `.env` ni `node_modules`.
- [ ] `docker image ls lab02-contexto` lista los tres tags: `sin-ignore`, `con-ignore` y `avanzado`.

## Limpieza

```bash
docker image rm lab02-contexto:sin-ignore lab02-contexto:con-ignore lab02-contexto:avanzado 2>/dev/null || true
rm -rf ~/workspace/lab02-contexto
```

Verifica:

```bash
docker image ls lab02-contexto
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| El contexto sigue siendo grande con `.dockerignore` | El archivo `.dockerignore` está fuera del directorio raíz del build | Verificar que `.dockerignore` está en el mismo directorio que `Dockerfile` |
| `COPY app.js .` falla con "not found" | `app.js` quedó excluido por un patrón muy amplio en `.dockerignore` | Revisar el `.dockerignore`; un patrón `*.js` excluiría también `app.js` |
| `dd` no disponible | Sistema sin el comando `dd` | Alternativa: `python3 -c "open('node_modules/paquete-pesado/binario.bin','wb').write(b'x'*10*1024*1024)"` |
