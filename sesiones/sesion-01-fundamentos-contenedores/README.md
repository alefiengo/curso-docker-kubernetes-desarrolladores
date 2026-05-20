# Sesión 1: Fundamentos de Contenedores

## Objetivo

Entender qué problema resuelven los contenedores y ejecutar los primeros comandos Docker.

## Duración

2 horas.

## Materiales

- [Instalación del entorno Docker](../../docs/instalacion-entorno-docker.md)
- [Referencia rápida](referencia-rapida.md)
- [Desafío opcional](tareas/desafio-opcional.md)

## Laboratorios

| Lab | Tema |
|---|---|
| [01 – Hello World](labs/01-hello-world/README.md) | Primer contenedor y flujo de descarga de imagen |
| [02 – Nginx en segundo plano](labs/02-nginx/README.md) | Modo `-d`, mapeo de puertos y ciclo de vida |
| [03 – Contenedor interactivo](labs/03-contenedor-interactivo/README.md) | Modo `-it`, aislamiento y `docker exec` |
| [04 – Docker Hub y tags](labs/04-docker-hub/README.md) | Registro, versiones y criterios de selección de imagen |

## Al finalizar esta sesión podrás

- Explicar la diferencia práctica entre imagen y contenedor.
- Ejecutar contenedores en primer plano, segundo plano y modo interactivo.
- Publicar un servicio web local con mapeo de puertos.
- Consultar logs, estado y detalles básicos de un contenedor.
- Detener y eliminar los recursos creados.

## Conceptos Clave

### Imagen y contenedor

Una imagen es una plantilla de solo lectura con el sistema de archivos, dependencias y comando por defecto de una aplicación. Un contenedor es una instancia en ejecución de esa imagen: un proceso aislado que comparte el kernel del sistema operativo anfitrión.

La distinción práctica:

| Concepto | Idea clave | Comando |
|---|---|---|
| Imagen | Plantilla de solo lectura | `docker image ls` |
| Contenedor | Proceso creado desde una imagen | `docker container ls` |
| Crear e iniciar | Crea un contenedor nuevo y lo arranca | `docker run` |
| Iniciar existente | Arranca un contenedor ya creado | `docker start` |

### Por qué un contenedor termina o sigue vivo

Un contenedor vive mientras su proceso principal esté activo. `hello-world` termina porque su proceso imprime un mensaje y sale. `nginx` sigue corriendo porque su proceso principal queda escuchando peticiones.

### Registro

Un registro almacena imágenes. Docker Hub es el registro público por defecto. Cuando ejecutas `docker run nginx:alpine` y la imagen no existe localmente, Docker la descarga automáticamente desde el registro.

### Docker Engine

Docker Engine recibe los comandos del cliente Docker, descarga imágenes cuando hace falta, crea contenedores y administra su ciclo de vida.

## Comandos de la Sesión

```bash
docker --version
docker info
docker run
docker ps
docker ps -a
docker logs
docker inspect
docker top
docker stop
docker start
docker rm
docker exec
```

Formas explícitas equivalentes:

```bash
docker container ls
docker container ls -a
docker image ls
```

## Validación General

Cuando completes los cuatro labs, ejecuta:

```bash
bash scripts/estado.sh
docker ps -a --filter "name=lab-"
```

La sesión está completa si:

- [ ] `lab-hello` existe con estado `Exited`.
- [ ] `lab-web` responde en `http://localhost:8080`.
- [ ] `lab-shell` existe con estado `Exited`.
- [ ] Tienes al menos dos variantes de `nginx` descargadas.

## Limpieza

```bash
bash scripts/limpiar.sh
```

O manualmente:

```bash
docker rm lab-hello
docker rm -f lab-web lab-shell
docker rm -f lab-hub-latest lab-hub-alpine
```

Verificar que no quedan contenedores del laboratorio:

```bash
docker ps -a --filter "name=lab-"
```

## Desafío Opcional

El [desafío opcional](tareas/desafio-opcional.md) propone una exploración libre con una imagen de tu elección. No se entrega y no es requisito para la siguiente sesión.

## Cierre

Checklist:

- [ ] Puedo ejecutar un contenedor.
- [ ] Puedo publicar un puerto local.
- [ ] Puedo ver logs.
- [ ] Puedo inspeccionar un contenedor.
- [ ] Puedo detener y eliminar recursos.
- [ ] Puedo explicar la diferencia entre imagen y contenedor.

Preguntas de repaso:

- ¿Qué diferencia hay entre imagen y contenedor?
- ¿Por qué `hello-world` termina y `nginx` queda ejecutándose?
- ¿Qué hace el mapeo `-p 8080:80`?
- ¿Cuándo usarías `docker exec` en lugar de `docker run -it`?

## Preparación para la Siguiente Sesión

La sesión 2 profundiza en imágenes: capas, tags, inspección, variables de entorno y volúmenes introductorios. No es necesario completar el desafío opcional para avanzar.
