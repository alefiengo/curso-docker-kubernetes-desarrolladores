# Sesión 2: Imágenes, Docker Hub y Ciclo de Vida

## Objetivo

Comprender la estructura interna de las imágenes Docker, gestionar su ciclo de vida completo y persistir datos entre recreaciones de contenedores usando volúmenes nombrados.

## Duración

2 horas.

## Materiales

- [Referencia rápida](referencia-rapida.md)
- [Desafío opcional](tareas/desafio-opcional.md)

## Laboratorios

| # | Nombre | Tema |
|---|---|---|
| [01](labs/01-inspeccion-imagenes/README.md) | Inspección de imágenes | Capas, metadatos, historial y comparación de tags |
| [02](labs/02-variables-ciclo-vida/README.md) | Variables de entorno y ciclo de vida | Pasar configuración a contenedores, estados y comandos de gestión |
| [03](labs/03-volumenes-intro/README.md) | Volúmenes introductorios | Persistencia de datos con volúmenes nombrados y bind mounts |

## Al finalizar esta sesión podrás

- Explicar qué es una capa de imagen y cómo se comparten entre tags.
- Inspeccionar metadatos, historial y digest de una imagen con `docker image inspect` e `docker image history`.
- Pasar variables de entorno a un contenedor con `-e` y `--env-file`.
- Describir los estados del ciclo de vida de un contenedor: creado, corriendo, detenido, eliminado.
- Demostrar que los datos se pierden al eliminar un contenedor sin volumen.
- Persistir datos entre recreaciones usando un volumen nombrado con `-v`.
- Distinguir entre volumen nombrado y bind mount.

## Conceptos Clave

### Capas e imágenes

Una imagen Docker es una pila de capas de solo lectura. Cada instrucción del `Dockerfile` que modifica el sistema de archivos genera una capa nueva. Las capas se identifican por su hash SHA256 y se comparten entre imágenes que las tienen en común.

```
nginx:1.30-alpine
├── capa base Alpine Linux       ← compartida con nginx:1.27-alpine si usan el mismo Alpine
├── capa paquetes nginx
├── capa configuración por defecto
└── capa metadatos (CMD, EXPOSE) ← no ocupa espacio en disco
```

Cuando haces `docker pull nginx:1.30-alpine` y ya tienes `nginx:1.27-alpine`, Docker descarga solo las capas que difieren. Las capas compartidas no se duplican en disco.

### Tags y digest

Un tag es un apuntador mutable a una imagen. `nginx:alpine` puede apuntar a builds distintos en momentos distintos. El digest (`sha256:...`) es el identificador inmutable: dos imágenes con el mismo digest son bit a bit idénticas.

Para reproducibilidad en entornos productivos, fija tanto la versión como la variante: `nginx:1.30-alpine`.

### Ciclo de vida del contenedor

```
docker create  →  [created]
docker start   →  [running]
docker stop    →  [exited]   ← el sistema de archivos persiste
docker start   →  [running]
docker rm      →  eliminado  ← el sistema de archivos se borra
```

La diferencia entre `docker stop` y `docker rm` es crítica: `stop` detiene el proceso pero conserva el contenedor y sus datos internos. `rm` lo elimina definitivamente.

### Variables de entorno

Las variables de entorno son el mecanismo estándar para configurar imágenes de Docker Hub sin modificarlas. La documentación de cada imagen en hub.docker.com lista las variables que acepta.

```bash
# Forma explícita
docker run -e POSTGRES_PASSWORD=secreto postgres:16-alpine

# Desde archivo (recomendado para no exponer valores en el historial del shell)
docker run --env-file variables.env postgres:16-alpine
```

### Volúmenes nombrados vs bind mounts

| | Volumen nombrado | Bind mount |
|---|---|---|
| Gestión | Docker gestiona la ubicación | Tú eliges la ruta en el anfitrión |
| Portabilidad | Alta: funciona igual en cualquier sistema | Depende de la estructura de directorios del anfitrión |
| Uso típico | Datos de bases de datos, estado de aplicación | Código fuente en desarrollo, archivos de configuración |
| Sintaxis | `-v nombre:/ruta/interna` | `-v /ruta/anfitrion:/ruta/interna` |

## Comandos de la Sesión

```bash
# Imágenes
docker pull nginx:alpine
docker pull nginx:1.30-alpine
docker image ls
docker image ls nginx
docker image inspect nginx:alpine
docker image inspect nginx:alpine --format '{{.Os}}/{{.Architecture}}'
docker image inspect nginx:alpine --format '{{.Config.Cmd}}'
docker image inspect nginx:alpine --format '{{range .Config.Env}}{{println .}}{{end}}'
docker image inspect nginx:alpine --format '{{len .RootFS.Layers}}'
docker image inspect nginx:alpine --format '{{index .RepoDigests 0}}'
docker image history nginx:alpine
docker image rm nginx:alpine
docker image prune

# Contenedores con variables de entorno
docker run -d --name contenedor -e VARIABLE=valor imagen:tag
docker run -d --name contenedor --env-file variables.env imagen:tag
docker inspect contenedor --format '{{range .Config.Env}}{{println .}}{{end}}'
docker logs contenedor
docker logs -f contenedor
docker top contenedor
docker stop contenedor
docker start contenedor
docker exec -it contenedor bash

# Volúmenes
docker volume create nombre-volumen
docker volume ls
docker volume inspect nombre-volumen
docker volume rm nombre-volumen
docker run -d -v nombre-volumen:/ruta/interna imagen:tag
docker run -d -v /ruta/local:/ruta/interna imagen:tag
```

## Validación General

- [ ] `docker image ls nginx` muestra al menos dos tags.
- [ ] `docker image history nginx:alpine` lista al menos cinco capas.
- [ ] `docker image inspect nginx:alpine --format '{{len .RootFS.Layers}}'` devuelve un número mayor que 0.
- [ ] Pudiste verificar que los datos se pierden sin volumen al recrear el contenedor.
- [ ] `docker volume ls` muestra el volumen creado en el lab 03.
- [ ] Los datos persisten al eliminar y recrear el contenedor con volumen nombrado.

## Limpieza

```bash
docker rm -f $(docker ps -aq --filter "name=lab-") 2>/dev/null || true
docker volume prune -f
docker image rm nginx:alpine nginx:1.27-alpine nginx:1.30-alpine postgres:16-alpine 2>/dev/null || true
```

Verifica:

```bash
docker ps -a --filter "name=lab-"
docker volume ls
```

## Desafío Opcional

Elige una imagen de Docker Hub que no hayas usado antes, analiza su estructura y verifica la persistencia de datos con un volumen nombrado.

Ver instrucciones completas en [tareas/desafio-opcional.md](tareas/desafio-opcional.md).

## Cierre

Antes de cerrar la sesión, verifica que puedes responder:

- [ ] ¿Qué es una capa de imagen y por qué dos tags pueden compartir el mismo IMAGE ID?
- [ ] ¿Cuál es la diferencia entre `docker stop` y `docker rm`?
- [ ] ¿Por qué se prefiere `--env-file` sobre `-e` para contraseñas?
- [ ] ¿Qué ocurre con los datos de un contenedor cuando lo eliminas sin volumen?
- [ ] ¿Cuándo usarías un bind mount en lugar de un volumen nombrado?

## Preparación para la Siguiente Sesión

En la sesión 3 construirás tu primera imagen propia con un `Dockerfile`. Asegúrate de tener Docker funcionando y una cuenta en [hub.docker.com](https://hub.docker.com/) activa.
