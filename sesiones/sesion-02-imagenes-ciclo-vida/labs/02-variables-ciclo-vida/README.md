# Lab 02: Variables de Entorno y Ciclo de Vida

## Objetivo

Pasar variables de entorno a un contenedor, inspeccionar el estado del proceso principal y entender el ciclo de vida completo: creado, corriendo, detenido, eliminado.

## Requisitos

- Docker Engine funcionando.
- Lab 01 completado o equivalente: sabes hacer `docker pull` y `docker image inspect`.

## Paso a paso

### 1. Ejecutar un contenedor con variables de entorno

Las variables de entorno permiten configurar el comportamiento de la aplicación sin modificar la imagen. Se pasan con `-e` o `--env`.

```bash
docker run -d \
  --name lab-postgres \
  -e POSTGRES_USER=curso \
  -e POSTGRES_PASSWORD=secreto \
  -e POSTGRES_DB=appdb \
  -p 5432:5432 \
  postgres:16-alpine
```

`postgres:16-alpine`: imagen oficial de PostgreSQL, rama LTS activa, variante Alpine.

### 2. Verificar que el contenedor está corriendo

```bash
docker ps --filter "name=lab-postgres"
```

La columna `STATUS` debe mostrar `Up`. Si muestra `Exited`, hubo un error en el arranque.

### 3. Inspeccionar las variables de entorno del contenedor en ejecución

```bash
docker inspect lab-postgres --format '{{range .Config.Env}}{{println .}}{{end}}'
```

Verás las variables que pasaste más las que trae la imagen por defecto.

### 4. Ver los logs de arranque

```bash
docker logs lab-postgres
```

PostgreSQL escribe en los logs si el servidor arrancó correctamente. Busca la línea:

```
database system is ready to accept connections
```

Para seguir los logs en tiempo real:

```bash
docker logs -f lab-postgres
```

Sal con `Ctrl+C`. El contenedor sigue corriendo.

### 5. Ejecutar un comando dentro del contenedor

```bash
docker exec -it lab-postgres psql -U curso -d appdb
```

Una vez dentro:

```sql
\conninfo
\l
\q
```

`\conninfo` confirma el usuario y base de datos activos. `\l` lista las bases de datos. `\q` cierra la sesión.

### 6. Inspeccionar el proceso principal

```bash
docker top lab-postgres
```

Muestra los procesos del contenedor vistos desde el anfitrión. El proceso principal de PostgreSQL debe estar en la lista.

### 7. Detener y reiniciar el contenedor

```bash
docker stop lab-postgres
docker ps -a --filter "name=lab-postgres"
```

El estado cambia a `Exited`. El contenedor existe pero no corre.

Reinícialo:

```bash
docker start lab-postgres
docker ps --filter "name=lab-postgres"
```

El estado vuelve a `Up`. Los datos dentro del contenedor se mantienen porque el sistema de archivos del contenedor persiste entre reinicios — pero desaparecerán si haces `docker rm`.

### 8. Pasar variables desde un archivo

Para no exponer contraseñas en la historia del shell, usa `--env-file`:

```bash
cat > /tmp/lab-env.txt <<EOF
POSTGRES_USER=curso
POSTGRES_PASSWORD=secreto
POSTGRES_DB=appdb
EOF

docker run -d \
  --name lab-postgres-env \
  --env-file /tmp/lab-env.txt \
  -p 5433:5432 \
  postgres:16-alpine
```

Verifica:

```bash
docker ps --filter "name=lab-postgres-env"
docker logs lab-postgres-env | tail -5
```

## Validación

- [ ] `docker ps` muestra `lab-postgres` con estado `Up`.
- [ ] `docker logs lab-postgres` contiene `database system is ready to accept connections`.
- [ ] `docker exec -it lab-postgres psql -U curso -d appdb -c '\conninfo'` responde sin error.
- [ ] Después de `docker stop` + `docker start`, el contenedor vuelve a estado `Up`.

## Limpieza

```bash
docker rm -f lab-postgres lab-postgres-env
rm -f /tmp/lab-env.txt
```

Verifica que no queda ninguno:

```bash
docker ps -a --filter "name=lab-postgres"
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| `Error: Database is uninitialized and password is not specified` | Falta `POSTGRES_PASSWORD` | Agrega `-e POSTGRES_PASSWORD=...` al comando |
| `port is already allocated` | El puerto 5432 está ocupado en el anfitrión | Cambia el puerto local: `-p 5433:5432` |
| `psql: error: connection refused` | El contenedor aún está iniciando | Espera 2–3 segundos y reintenta |
| Contenedor en estado `Restarting` | Falta una variable de entorno requerida | Revisa `docker logs` para ver el error de arranque |
