# Lab 01: Primer Dockerfile

## Objetivo

Escribir un `Dockerfile` desde cero para servir una página HTML estática con nginx, construir la imagen y verificar que el contenedor arranca y responde.

## Requisitos

- Docker funcionando (`docker version` responde sin error).
- Directorio de trabajo limpio: `~/workspace/lab01-web/`.

## Paso a paso

### 1. Crear el directorio de trabajo

El build context será este directorio. Docker enviará al daemon todo lo que esté aquí.

```bash
mkdir -p ~/workspace/lab01-web
cd ~/workspace/lab01-web
```

### 2. Crear el contenido HTML

Necesitas un archivo que nginx pueda servir. Créalo con el siguiente contenido:

```bash
cat > index.html <<'EOF'
<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><title>Lab 01</title></head>
<body>
  <h1>Sesión 3 - Lab 01</h1>
  <p>Imagen construida con Dockerfile propio.</p>
</body>
</html>
EOF
```

### 3. Escribir el Dockerfile

Cada instrucción tiene un propósito concreto que el siguiente bloque explica.

```bash
cat > Dockerfile <<'EOF'
# FROM define la imagen base. Usar un tag fijo evita sorpresas entre builds.
FROM nginx:1.27-alpine

# LABEL agrega metadatos legibles para quien inspeccione la imagen.
LABEL descripcion="Lab 01 - Primer Dockerfile"

# WORKDIR establece el directorio de trabajo para las instrucciones siguientes.
# Si no existe, Docker lo crea. Evita usar rutas relativas sueltas.
WORKDIR /usr/share/nginx/html

# COPY toma el archivo desde el build context y lo coloca en la imagen.
# El destino es relativo a WORKDIR.
COPY index.html .

# EXPOSE documenta el puerto en que nginx escucha. No lo publica en el host.
EXPOSE 80

# CMD define el comando por defecto al arrancar el contenedor.
# Forma exec: el proceso es PID 1 y recibe señales correctamente.
CMD ["nginx", "-g", "daemon off;"]
EOF
```

### 4. Construir la imagen

El punto final (`.`) indica que el build context es el directorio actual. Docker envía ese directorio al daemon y ejecuta cada instrucción del `Dockerfile`.

```bash
docker build -t lab01-web:1.0 .
```

Observa la salida: cada instrucción aparece como un paso numerado. Las instrucciones que no cambiaron entre builds muestran `CACHED`.

### 5. Verificar la imagen construida

```bash
docker image ls lab01-web
docker image history lab01-web:1.0
```

`history` muestra cada capa con su tamaño. Las instrucciones `LABEL`, `EXPOSE` y `CMD` no añaden espacio en disco.

### 6. Ejecutar el contenedor

```bash
docker run -d --name lab01-web -p 8081:80 lab01-web:1.0
```

Mapeas el puerto 80 del contenedor al 8081 de tu máquina.

### 7. Verificar la respuesta

```bash
curl http://localhost:8081
```

Debes ver el HTML de `index.html`. También puedes abrir `http://localhost:8081` en el navegador.

### 8. Inspeccionar el contenedor

```bash
# Ver logs de nginx
docker logs lab01-web

# Ver los metadatos completos del contenedor
docker inspect lab01-web

# Verificar que el proceso es PID 1 dentro del contenedor
docker exec lab01-web ps aux
```

### 9. Modificar y reconstruir (caché en acción)

Edita `index.html` y cambia el texto del párrafo. Luego reconstruye:

```bash
docker build -t lab01-web:1.1 .
```

Observa que las instrucciones `FROM`, `LABEL` y `WORKDIR` muestran `CACHED`. Solo las capas a partir de `COPY` se recalculan porque el contenido del archivo cambió.

## Validación

- [ ] `docker image ls lab01-web` muestra los tags `1.0` y `1.1`.
- [ ] `docker image history lab01-web:1.0` muestra la instrucción `COPY` con tamaño mayor que 0.
- [ ] `curl http://localhost:8081` devuelve el HTML con el texto del paso 2.
- [ ] `docker exec lab01-web ps aux` muestra `nginx` como PID 1.
- [ ] Al reconstruir con `1.1`, las capas anteriores a `COPY` muestran `CACHED`.

## Limpieza

```bash
docker rm -f lab01-web
docker image rm lab01-web:1.0 lab01-web:1.1 2>/dev/null || true
rm -rf ~/workspace/lab01-web
```

Verifica:

```bash
docker ps -a --filter "name=lab01-web"
docker image ls lab01-web
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| `failed to solve: failed to read dockerfile` | El archivo se llama `dockerfile` en minúsculas o tiene otra extensión | Verificar con `ls -la` y renombrar: `mv dockerfile Dockerfile` |
| `bind: address already in use` al ejecutar el contenedor | El puerto 8081 ya está ocupado | Usar otro puerto: `-p 8082:80` |
| `curl: (7) Failed to connect` | El contenedor no está corriendo | Verificar con `docker ps` y ver logs con `docker logs lab01-web` |
| Las instrucciones no se cachean | Se construyó con `--no-cache` o el Dockerfile cambió | Normal; `--no-cache` descarta la caché deliberadamente |
