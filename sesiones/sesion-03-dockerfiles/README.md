# Sesión 3: Dockerfiles y Publicación

## Objetivo

Construir imágenes Docker propias a partir de un `Dockerfile`, comprender las instrucciones principales, controlar el contexto de build y publicar una imagen en Docker Hub.

## Duración

2 horas.

## Materiales

- [Referencia rápida](referencia-rapida.md)
- [Desafío opcional](tareas/desafio-opcional.md)

## Laboratorios

| # | Nombre | Tema |
|---|---|---|
| [01](labs/01-primer-dockerfile/README.md) | Primer Dockerfile | Instrucciones FROM, WORKDIR, COPY, RUN, EXPOSE y CMD sobre nginx |
| [02](labs/02-build-context/README.md) | Build context y .dockerignore | Qué se envía al daemon, qué excluir y cómo medir el impacto |
| [03](labs/03-cmd-entrypoint/README.md) | CMD vs ENTRYPOINT | Diferencias prácticas entre las dos instrucciones de arranque |
| [04](labs/04-docker-hub-push/README.md) | Publicar en Docker Hub | Tag, login, push y verificación de la imagen publicada |

## Al finalizar esta sesión podrás

- Escribir un `Dockerfile` con las instrucciones fundamentales: `FROM`, `WORKDIR`, `COPY`, `RUN`, `EXPOSE`, `ENV`, `ARG`, `LABEL`, `CMD` y `ENTRYPOINT`.
- Explicar qué es el build context y cómo afecta al tamaño y la velocidad del build.
- Crear un `.dockerignore` para excluir archivos innecesarios del contexto.
- Distinguir entre `CMD` y `ENTRYPOINT` y elegir cuál usar según el caso.
- Construir una imagen con `docker build` y verificar el resultado.
- Etiquetar la imagen con tu usuario de Docker Hub y publicarla con `docker push`.

## Conceptos Clave

### Qué es un Dockerfile

Un `Dockerfile` es un archivo de texto plano con instrucciones secuenciales para construir una imagen de forma automatizada y reproducible. Cada instrucción genera una capa de solo lectura que se apila sobre la anterior. El resultado final es una imagen que puedes ejecutar como contenedor en cualquier máquina con Docker.

```
Dockerfile
    |
docker build
    |
    +-- capa FROM   (imagen base)
    +-- capa RUN    (paquetes, configuración)
    +-- capa COPY   (archivos de la app)
    +-- capa CMD    (metadatos, sin espacio en disco)
    |
  imagen propia
```

### Instrucciones principales

| Instrucción | Para qué sirve | Ejemplo |
|---|---|---|
| `FROM` | Imagen base de partida. Siempre la primera instrucción. | `FROM nginx:1.27-alpine` |
| `WORKDIR` | Directorio de trabajo dentro de la imagen para las instrucciones siguientes. | `WORKDIR /app` |
| `COPY` | Copia archivos desde el build context a la imagen. | `COPY index.html /usr/share/nginx/html/` |
| `ADD` | Como `COPY` pero también desempaqueta tarballs y soporta URLs. Preferir `COPY` salvo que necesites esas funciones extra. | `ADD app.tar.gz /app/` |
| `RUN` | Ejecuta un comando durante el build y guarda el resultado como capa. | `RUN apt-get update && apt-get install -y curl` |
| `ENV` | Define variables de entorno disponibles en build y en tiempo de ejecución. | `ENV NODE_ENV=production` |
| `ARG` | Define variables disponibles solo durante el build, no en el contenedor. | `ARG VERSION=1.0` |
| `EXPOSE` | Documenta en qué puerto escucha la aplicación. No publica el puerto; eso lo hace `-p` en `docker run`. | `EXPOSE 80` |
| `LABEL` | Metadatos de la imagen: autor, versión, descripción. | `LABEL maintainer="tu@email.com"` |
| `USER` | Cambia el usuario que ejecuta las instrucciones siguientes y el proceso final. | `USER nobody` |
| `CMD` | Comando por defecto al arrancar el contenedor. Reemplazable pasando argumentos a `docker run`. | `CMD ["nginx", "-g", "daemon off;"]` |
| `ENTRYPOINT` | Ejecutable fijo del contenedor. Los argumentos de `docker run` se le pasan como parámetros. | `ENTRYPOINT ["python", "app.py"]` |

### Caché de build

Cuando reconstruyes una imagen, Docker reutiliza las capas que no han cambiado. En cuanto una instrucción difiere —por ejemplo porque el contenido de un `COPY` cambió— Docker invalida esa capa y todas las siguientes.

Esto tiene una consecuencia práctica importante: **el orden de las instrucciones afecta la velocidad de los builds sucesivos**. Pon primero lo que cambia menos y al final lo que cambia con frecuencia:

```dockerfile
# Orden que aprovecha la caché
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./        # Cambia solo cuando agregas dependencias
RUN npm ci --omit=dev        # Se cachea si package*.json no cambió
COPY . .                     # Cambia con cada edición de código
```

### Build context

El build context es el conjunto de archivos que Docker envía al daemon antes de ejecutar el `Dockerfile`. Por defecto es todo el directorio desde donde ejecutas `docker build`. Si ese directorio tiene cientos de megabytes, cada build será lento aunque tu `Dockerfile` solo use diez archivos.

El build context **no** es lo que Docker lee durante el build; es lo que pone a disposición de las instrucciones `COPY` y `ADD`. Solo los archivos dentro del contexto son accesibles.

### .dockerignore

El archivo `.dockerignore` funciona igual que `.gitignore`: lista patrones de archivos y directorios que Docker excluye del build context. Siempre incluirlo en proyectos reales.

Exclusiones típicas:

```
.git
.env
node_modules
*.log
__pycache__
.DS_Store
```

### CMD vs ENTRYPOINT

Ambas definen qué ejecuta el contenedor, pero con comportamientos distintos:

| Configuración | Comando `docker run` | Resultado |
|---|---|---|
| `CMD ["nginx", "-g", "daemon off;"]` | `docker run imagen` | `nginx -g daemon off;` |
| `CMD ["nginx", "-g", "daemon off;"]` | `docker run imagen ls` | `ls` (CMD reemplazado) |
| `ENTRYPOINT ["nginx"]` | `docker run imagen` | `nginx` |
| `ENTRYPOINT ["nginx"]` | `docker run imagen -v` | `nginx -v` |
| `ENTRYPOINT ["nginx"] + CMD ["-g","daemon off;"]` | `docker run imagen` | `nginx -g daemon off;` |
| `ENTRYPOINT ["nginx"] + CMD ["-g","daemon off;"]` | `docker run imagen -v` | `nginx -v` (CMD reemplazado) |

Regla práctica:

- Usa `CMD` cuando el usuario puede necesitar cambiar el comando completo en `docker run`.
- Usa `ENTRYPOINT` cuando el contenedor tiene un único propósito ejecutable y los argumentos de `docker run` deben pasarle parámetros.
- Combínalos cuando quieras un ejecutable fijo (`ENTRYPOINT`) con parámetros por defecto sobrescribibles (`CMD`).

Usa siempre la **forma exec** (array JSON), nunca la forma shell:

```dockerfile
# Forma exec (recomendada): el proceso es PID 1, recibe señales correctamente
CMD ["nginx", "-g", "daemon off;"]

# Forma shell (evitar): envuelve el comando en /bin/sh -c, PID 1 es el shell
CMD nginx -g "daemon off;"
```

### Publicar en Docker Hub

Docker Hub es el registro público por defecto. Para publicar una imagen:

1. La imagen debe llevar el prefijo de tu usuario: `usuario/nombre:tag`.
2. Necesitas una sesión activa con `docker login`.
3. `docker push` sube solo las capas que Docker Hub no tiene todavía.

```bash
docker login
docker tag mi-imagen:1.0 usuario/mi-imagen:1.0
docker push usuario/mi-imagen:1.0
```

## Comandos de la Sesión

```bash
# Construir una imagen desde el directorio actual
docker build -t nombre:tag .

# Construir sin usar caché
docker build --no-cache -t nombre:tag .

# Construir desde un Dockerfile con otro nombre
docker build -f Dockerfile.prod -t nombre:tag .

# Construir pasando argumentos de build
docker build --build-arg VERSION=2.0 -t nombre:tag .

# Ver el historial de capas de una imagen
docker image history nombre:tag

# Inspeccionar metadatos de la imagen
docker image inspect nombre:tag

# Medir el impacto del build context (modo verbose)
docker build --progress=plain -t nombre:tag .

# Listar imágenes locales filtradas
docker image ls nombre

# Etiquetar para Docker Hub
docker tag nombre:tag usuario/nombre:tag

# Iniciar sesión en Docker Hub
docker login

# Publicar imagen
docker push usuario/nombre:tag

# Cerrar sesión
docker logout

# Eliminar imagen local
docker image rm nombre:tag

# Limpiar imágenes sin usar
docker image prune
```

## Validación General

- [ ] `docker image ls` muestra la imagen construida en el lab 01 con su tag.
- [ ] `docker image history` de la imagen del lab 01 muestra al menos tres capas propias.
- [ ] El contenedor del lab 01 responde en el puerto publicado con `curl`.
- [ ] El lab 02 demuestra que excluir `node_modules` del contexto reduce el tamaño enviado al daemon.
- [ ] El lab 03 muestra la diferencia entre pasar argumentos a un contenedor con `CMD` y con `ENTRYPOINT`.
- [ ] `docker pull tu-usuario/sesion03-web:1.0` descarga la imagen publicada en el lab 04 y el contenedor arranca correctamente.

## Limpieza

```bash
docker rm -f $(docker ps -aq --filter "name=lab-") 2>/dev/null || true
docker image rm \
  lab01-web:1.0 lab01-web:1.1 \
  lab02-contexto:sin-ignore lab02-contexto:con-ignore lab02-contexto:avanzado \
  lab03-saludo:cmd lab03-saludo:entrypoint lab03-saludo:combo \
  lab03-saludo:script lab03-saludo:shell lab03-saludo:exec \
  sesion03-web:1.0 \
  2>/dev/null || true
docker image prune -f
```

Verifica:

```bash
docker ps -a --filter "name=lab-"
docker image ls | grep lab0
```

## Desafío Opcional

Dockeriza una aplicación propia (o una de muestra en Python, Node.js o Go) con al menos tres instrucciones del `Dockerfile` que no usaste en los labs, publícala en Docker Hub y verifica que otra persona puede hacer `docker pull` y ejecutarla sin el código fuente.

Ver instrucciones completas en [tareas/desafio-opcional.md](tareas/desafio-opcional.md).

## Cierre

Antes de cerrar la sesión, verifica que puedes responder:

- [ ] ¿Qué genera una nueva capa en una imagen Docker?
- [ ] ¿Por qué el orden de las instrucciones en un `Dockerfile` importa para la caché?
- [ ] ¿Cuál es la diferencia entre `COPY` y `ADD`? ¿Cuándo usarías `ADD`?
- [ ] ¿Qué archivos típicos conviene excluir del build context con `.dockerignore`?
- [ ] ¿Qué ocurre si pasas argumentos a `docker run` cuando la imagen usa `CMD`? ¿Y cuando usa `ENTRYPOINT`?
- [ ] ¿Qué pasos son necesarios para publicar una imagen en Docker Hub?

## Preparación para la Siguiente Sesión

En la sesión 4 trabajarás con multi-stage builds y optimización de imágenes. Asegúrate de tener al menos una imagen propia construida y de haber completado el lab 04 (publicación en Docker Hub).
