# Lab 03: Volúmenes Introductorios

## Objetivo

Entender por qué los datos desaparecen cuando se elimina un contenedor, y cómo un volumen nombrado resuelve ese problema para persistir datos entre recreaciones.

## Requisitos

- Docker Engine funcionando.
- Lab 02 completado: sabes ejecutar contenedores con variables de entorno.

## Paso a paso

### 1. El problema: datos que desaparecen al eliminar un contenedor

El sistema de archivos de un contenedor es efímero. Cuando lo eliminas con `docker rm`, ese sistema de archivos se borra junto con todos los datos que contenía.

Compruébalo:

```bash
docker run -d \
  --name lab-sin-volumen \
  -e POSTGRES_USER=curso \
  -e POSTGRES_PASSWORD=secreto \
  -e POSTGRES_DB=appdb \
  postgres:16-alpine

sleep 3

docker exec lab-sin-volumen psql -U curso -d appdb -c \
  "CREATE TABLE notas (id serial PRIMARY KEY, texto text);"

docker exec lab-sin-volumen psql -U curso -d appdb -c \
  "INSERT INTO notas (texto) VALUES ('dato importante');"

docker exec lab-sin-volumen psql -U curso -d appdb -c "SELECT * FROM notas;"
```

Elimina y recrea el contenedor sin volumen:

```bash
docker rm -f lab-sin-volumen

docker run -d \
  --name lab-sin-volumen \
  -e POSTGRES_USER=curso \
  -e POSTGRES_PASSWORD=secreto \
  -e POSTGRES_DB=appdb \
  postgres:16-alpine

sleep 3

docker exec lab-sin-volumen psql -U curso -d appdb -c "SELECT * FROM notas;"
```

La tabla no existe. Los datos se perdieron al eliminar el contenedor.

```bash
docker rm -f lab-sin-volumen
```

### 2. La solución: volumen nombrado

Un volumen nombrado es un directorio gestionado por Docker que existe fuera del ciclo de vida del contenedor. Cuando el contenedor se elimina, el volumen permanece.

```bash
docker volume create datos-postgres
docker volume ls
```

### 3. Montar el volumen en un contenedor

```bash
docker run -d \
  --name lab-con-volumen \
  -e POSTGRES_USER=curso \
  -e POSTGRES_PASSWORD=secreto \
  -e POSTGRES_DB=appdb \
  -v datos-postgres:/var/lib/postgresql/data \
  postgres:16-alpine
```

`-v datos-postgres:/var/lib/postgresql/data` conecta el volumen al directorio donde PostgreSQL almacena sus datos dentro del contenedor.

```bash
sleep 3

docker exec lab-con-volumen psql -U curso -d appdb -c \
  "CREATE TABLE notas (id serial PRIMARY KEY, texto text);"

docker exec lab-con-volumen psql -U curso -d appdb -c \
  "INSERT INTO notas (texto) VALUES ('dato persistente');"

docker exec lab-con-volumen psql -U curso -d appdb -c "SELECT * FROM notas;"
```

### 4. Eliminar el contenedor y verificar que los datos persisten

```bash
docker rm -f lab-con-volumen

docker volume ls
docker volume inspect datos-postgres
```

Recrea el contenedor usando el mismo volumen:

```bash
docker run -d \
  --name lab-con-volumen \
  -e POSTGRES_USER=curso \
  -e POSTGRES_PASSWORD=secreto \
  -e POSTGRES_DB=appdb \
  -v datos-postgres:/var/lib/postgresql/data \
  postgres:16-alpine

sleep 3

docker exec lab-con-volumen psql -U curso -d appdb -c "SELECT * FROM notas;"
```

Los datos siguen ahí. El volumen sobrevivió a la eliminación del contenedor.

### 5. Inspeccionar el volumen

```bash
docker volume inspect datos-postgres
```

El campo `Mountpoint` muestra dónde Docker almacena físicamente los datos en el anfitrión.

### 6. Diferencia entre bind mount y volumen nombrado

```bash
mkdir -p /tmp/lab-bind

docker run -d \
  --name lab-bind \
  -v /tmp/lab-bind:/usr/share/nginx/html:ro \
  -p 8082:80 \
  nginx:alpine

echo "<h1>Hola desde el bind mount</h1>" > /tmp/lab-bind/index.html
curl http://localhost:8082
```

Con un bind mount tú controlas la ruta en el anfitrión. Con un volumen nombrado, Docker gestiona la ubicación. Para datos de bases de datos se prefieren volúmenes nombrados.

## Validación

- [ ] Sin volumen: los datos desaparecen al eliminar y recrear el contenedor.
- [ ] Con volumen nombrado: los datos persisten después de eliminar y recrear el contenedor.
- [ ] `docker volume ls` muestra `datos-postgres`.
- [ ] `docker volume inspect datos-postgres` muestra el campo `Mountpoint`.
- [ ] El bind mount sirve `index.html` en `http://localhost:8082`.

## Limpieza

```bash
docker rm -f lab-con-volumen lab-bind
docker volume rm datos-postgres
rm -rf /tmp/lab-bind
```

Verifica:

```bash
docker ps -a --filter "name=lab-"
docker volume ls
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| `volume is in use` al eliminar | El contenedor que usa el volumen sigue activo | Elimina primero el contenedor: `docker rm -f <nombre>` |
| Datos no persisten aunque usé `-v` | Nombre del volumen o ruta interna incorrectos | Verifica con `docker inspect <contenedor>` la sección `Mounts` |
| `curl: (7) Failed to connect` | El contenedor no arrancó o el puerto es diferente | Verifica con `docker ps` que el contenedor está `Up` |
