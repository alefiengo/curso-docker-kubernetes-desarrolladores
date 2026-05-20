# Lab 02: Nginx en segundo plano

## Objetivo

Ejecutar un servidor web en segundo plano, publicar su puerto al sistema anfitrión y practicar los comandos de ciclo de vida de un contenedor activo.

## Requisitos

- Lab 01 completado o Docker en ejecución.
- Puerto `8080` disponible en el sistema anfitrión.

## Paso a paso

### 1. Ejecutar Nginx en segundo plano

```bash
docker run -d --name lab-web -p 8080:80 nginx:alpine
```

Desglose:

| Parte | Significado |
|---|---|
| `-d` | Ejecuta el contenedor en segundo plano y devuelve el control a la terminal |
| `--name lab-web` | Asigna un nombre fijo para usar en los comandos siguientes |
| `-p 8080:80` | Publica el puerto 80 del contenedor en el puerto 8080 del anfitrión |
| `nginx:alpine` | Imagen oficial de Nginx en variante Alpine (ligera) |

### 2. Verificar el estado

```bash
docker ps --filter "name=lab-web"
```

La columna `PORTS` debe mostrar `0.0.0.0:8080->80/tcp`. La columna `STATUS` debe mostrar `Up`.

Flujo del tráfico:

```text
anfitrión:8080  →  contenedor:80  →  nginx
```

### 3. Probar el servicio

```bash
curl http://localhost:8080
```

También puedes abrir en el navegador:

```text
http://localhost:8080
```

Resultado esperado: HTML de bienvenida de Nginx.

### 4. Revisar los logs

```bash
docker logs --tail 10 lab-web
docker logs -f lab-web
```

Cada petición HTTP genera una línea de log. Presiona `Ctrl+C` para salir del modo de seguimiento.

### 5. Inspeccionar el contenedor

```bash
docker inspect lab-web
docker top lab-web
```

`docker inspect` devuelve la configuración completa en formato JSON: red, volúmenes, variables de entorno y más. `docker top` muestra los procesos en ejecución dentro del contenedor.

### 6. Detener, iniciar y verificar

```bash
docker stop lab-web
docker ps
docker start lab-web
docker ps --filter "name=lab-web"
curl http://localhost:8080
```

El contenedor vuelve al estado `Up` con la misma configuración. El puerto sigue publicado.

## Validación

```bash
docker ps --filter "name=lab-web"
curl http://localhost:8080
docker logs --tail 5 lab-web
```

La práctica está completa si:

- [ ] `lab-web` aparece con estado `Up` y el puerto `8080->80` mapeado.
- [ ] `curl` devuelve HTML de bienvenida de Nginx.
- [ ] Puedes detener y volver a iniciar el contenedor sin perder la configuración.

## Limpieza

```bash
docker rm -f lab-web
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| `Bind for 0.0.0.0:8080 failed: port is already allocated` | El puerto 8080 está ocupado | Usar `-p 8081:80` y acceder por el puerto 8081 |
| `The container name "/lab-web" is already in use` | Contenedor previo con el mismo nombre | `docker rm -f lab-web` y volver a ejecutar |
| Nginx no responde en el navegador | El contenedor no está en ejecución | Verificar con `docker ps` y los logs con `docker logs lab-web` |
