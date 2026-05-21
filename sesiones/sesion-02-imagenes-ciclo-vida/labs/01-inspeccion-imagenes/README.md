# Lab 01: Inspección de Imágenes

## Objetivo

Explorar la estructura de una imagen Docker: capas, metadatos, historial y diferencias entre tags.

## Requisitos

- Docker Engine funcionando (`docker version` responde sin errores).
- Sesión 1 completada: sabes ejecutar `docker run` y `docker ps`.

## Paso a paso

### 1. Descargar imágenes sin ejecutarlas

Una imagen no necesita ejecutarse para poder inspeccionarla. `docker pull` la descarga y almacena en el cache local.

```bash
docker pull nginx:alpine
docker pull nginx:1.27-alpine
docker pull nginx:1.30-alpine
```

Cada tag apunta a un build diferente. Docker descarga solo las capas que aún no tiene en local.

### 2. Listar las imágenes descargadas

```bash
docker image ls nginx
```

Observa:

| Columna | Qué muestra |
|---|---|
| `REPOSITORY` | Nombre de la imagen |
| `TAG` | Versión o variante |
| `IMAGE ID` | Identificador único. Puede coincidir entre tags que apuntan al mismo build |
| `SIZE` | Tamaño descomprimido en disco |

### 3. Inspeccionar metadatos completos

`docker image inspect` devuelve la configuración interna en JSON.

```bash
docker image inspect nginx:alpine
```

Los campos más útiles de forma aislada:

```bash
# Sistema operativo y arquitectura
docker image inspect nginx:alpine --format '{{.Os}}/{{.Architecture}}'

# Comando por defecto al iniciar el contenedor
docker image inspect nginx:alpine --format '{{.Config.Cmd}}'

# Variables de entorno configuradas en la imagen
docker image inspect nginx:alpine --format '{{range .Config.Env}}{{println .}}{{end}}'

# Número de capas
docker image inspect nginx:alpine --format '{{len .RootFS.Layers}}'
```

### 4. Ver el historial de capas

Cada instrucción del Dockerfile que generó la imagen crea una capa. `docker image history` muestra ese historial.

```bash
docker image history nginx:alpine
```

Observa:
- Cada fila es una capa o un paso de construcción.
- La columna `SIZE` indica cuánto espacio agrega esa capa.
- Las capas con `0B` son instrucciones que no modifican el sistema de archivos (`EXPOSE`, `ENV`, `CMD`).

Compara el historial entre dos tags:

```bash
docker image history nginx:1.27-alpine
docker image history nginx:1.30-alpine
```

### 5. Comparar IDs entre tags

Cuando dos tags apuntan al mismo build, comparten el IMAGE ID y no ocupan espacio extra.

```bash
docker image ls nginx --format "table {{.Tag}}\t{{.ID}}\t{{.Size}}"
```

### 6. Verificar el digest de una imagen

El digest es el hash SHA256 del manifiesto. Es la referencia más precisa: dos imágenes con el mismo digest son bit a bit idénticas.

```bash
docker image inspect nginx:alpine --format '{{index .RepoDigests 0}}'
```

El digest también aparece en la salida de `docker pull`:

```bash
docker pull nginx:1.30-alpine
# Digest: sha256:...
```

## Validación

- [ ] `docker image ls nginx` muestra al menos tres tags de nginx.
- [ ] `docker image inspect nginx:alpine --format '{{.Os}}/{{.Architecture}}'` responde `linux/amd64` (o `linux/arm64` en Apple Silicon).
- [ ] `docker image history nginx:alpine` lista al menos cinco capas.
- [ ] Puedes explicar por qué dos tags pueden tener el mismo IMAGE ID.

## Limpieza

Las imágenes de este lab se reutilizan en el lab 02. No las elimines todavía.

Al finalizar la sesión:

```bash
docker image rm nginx:alpine nginx:1.27-alpine nginx:1.30-alpine
docker image ls nginx
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| `pull access denied` | Tag inexistente o imagen privada | Verifica el tag en hub.docker.com |
| `docker: command not found` | Docker no está en el PATH | Abre una nueva terminal o verifica la instalación |
| `Cannot connect to the Docker daemon` | Docker Engine no está corriendo | Abre Docker Desktop o ejecuta `sudo systemctl start docker` |
| Descarga muy lenta | Red congestionada | Espera o reinicia Docker Desktop |
