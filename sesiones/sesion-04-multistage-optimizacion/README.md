# Sesión 4: Multi-stage Builds y Optimización

## Objetivo

Reducir el tamaño y la superficie de ataque de las imágenes propias aplicando multi-stage builds, imágenes base minimales y usuario no privilegiado.

## Duración

2 horas.

## Materiales

- [Referencia rápida](referencia-rapida.md)
- [Desafío opcional](tareas/desafio-opcional.md)

## Laboratorios

| # | Nombre | Tema |
|---|---|---|
| [01](labs/01-multistage/README.md) | Multi-stage build | Separar la etapa de compilación de la imagen final para eliminar herramientas de build |
| [02](labs/02-usuario-no-root/README.md) | Usuario no root | Crear y usar un usuario sin privilegios para reducir la superficie de ataque |
| [03](labs/03-cache-capas/README.md) | Caché y orden de capas | Medir el impacto del orden de instrucciones en la velocidad de builds sucesivos |

## Al finalizar esta sesión podrás

- Explicar por qué una imagen de solo ejecución no necesita el compilador ni las dependencias de build.
- Escribir un `Dockerfile` con múltiples etapas usando `FROM ... AS` y `COPY --from=`.
- Comparar el tamaño de una imagen single-stage versus multi-stage para la misma aplicación.
- Elegir entre `alpine`, `slim` y `distroless` según las necesidades del servicio.
- Crear un usuario no root en la imagen y designarlo como `USER` final.
- Ordenar las instrucciones del `Dockerfile` para aprovechar al máximo la caché de build.
- Medir el tiempo de rebuild con y sin caché para validar el efecto del orden.

## Conceptos Clave

### Por qué las imágenes se vuelven grandes

Cuando construyes una aplicación dentro de la imagen —compilar, instalar dependencias de build, generar artefactos— todas esas herramientas quedan en la imagen final aunque no sean necesarias para ejecutar la aplicación. Una imagen de Go compilado no necesita el compilador de Go en producción. Una imagen de Node.js compilado no necesita `devDependencies` ni el código fuente completo.

```
Imagen single-stage (Go)       Imagen multi-stage (Go)
────────────────────────       ───────────────────────
golang:1.22-alpine   ~250 MB   FROM scratch / alpine
código fuente                  binario compilado  ~10 MB
compilador
módulos de Go
binario compilado
────────────────────           ───────────────────────
TOTAL: ~280 MB                 TOTAL: ~10–15 MB
```

### Multi-stage builds

Un `Dockerfile` puede tener múltiples instrucciones `FROM`. Cada una inicia una etapa nueva con su propio sistema de archivos. Solo la última etapa genera la imagen final; las anteriores son desechadas.

```dockerfile
# Etapa 1: construcción
FROM golang:1.22-alpine AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /app/servidor .

# Etapa 2: imagen final
FROM alpine:3.21
WORKDIR /app
COPY --from=builder /app/servidor .
CMD ["./servidor"]
```

`COPY --from=builder` extrae exactamente el artefacto que necesitas de la etapa anterior. Todo lo demás —el compilador, el código fuente, el caché de módulos— queda en la etapa `builder` y no forma parte de la imagen final.

También puedes copiar desde una imagen externa sin definir una etapa intermedia:

```dockerfile
COPY --from=golang:1.22-alpine /usr/local/go/bin/go /usr/local/bin/go
```

### Imágenes base minimales

| Base | Tamaño aprox. | Incluye | Cuándo usarla |
|---|---|---|---|
| `ubuntu:24.04` | ~80 MB | shell, utils GNU, apt | Imagen de desarrollo o cuando necesitas herramientas interactivas |
| `debian:bookworm-slim` | ~75 MB | shell mínimo, sin extras | Aplicaciones que necesitan `apt` pero no el SO completo |
| `alpine:3.21` | ~7 MB | musl libc, BusyBox, apk | Aplicaciones que compilan con musl o imágenes de bajo peso |
| `distroless/static` | ~2 MB | sin shell, sin gestor de paquetes | Binarios estáticos que no necesitan libc |
| `scratch` | 0 MB | vacío | Binarios totalmente estáticos (Go con `CGO_ENABLED=0`) |

La elección depende de las dependencias en tiempo de ejecución. Un binario Go estático puede correr en `scratch`. Una aplicación Python necesita intérprete y librerías, por lo que `python:3.12-slim` es una opción razonable.

### Usuario no root

Por defecto, el proceso dentro de un contenedor corre como `root` (UID 0). Si el contenedor es comprometido, el atacante tiene permisos de root dentro del contenedor. En configuraciones que comparten el namespace de usuarios con el anfitrión, esto puede tener consecuencias fuera del contenedor.

La práctica estándar es crear un usuario sin privilegios y designarlo antes del comando de inicio:

```dockerfile
FROM alpine:3.21
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY --chown=appuser:appgroup . .
USER appuser
CMD ["./servidor"]
```

`addgroup -S` y `adduser -S` crean grupo y usuario de sistema (sin home, sin password, sin shell interactivo). `-G` los asocia. `COPY --chown` asigna la propiedad de los archivos directamente en la instrucción de copia, sin necesitar un `RUN chown` adicional.

Para imágenes basadas en Debian/Ubuntu se usa la misma lógica con `groupadd` y `useradd`:

```dockerfile
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
```

### Caché de build y orden de instrucciones

Docker evalúa cada instrucción del `Dockerfile` en orden. Si una instrucción produce exactamente el mismo resultado que en el build anterior, reutiliza la capa cacheada y salta a la siguiente. En cuanto una instrucción difiere, invalida esa capa y **todas las siguientes**.

Consecuencia práctica: las instrucciones que cambian con más frecuencia deben ir al final.

```dockerfile
# Orden subóptimo: cambiar una línea de código invalida la instalación de dependencias
FROM node:22-alpine
WORKDIR /app
COPY . .                        # Cambia con cada edición de código
RUN npm ci --omit=dev           # Se invalida aunque package.json no haya cambiado

# Orden óptimo: la instalación de dependencias solo se invalida cuando package.json cambia
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./           # Cambia solo cuando agregas o quitas paquetes
RUN npm ci --omit=dev           # Cacheado mientras package.json no cambie
COPY . .                        # Cambia con cada edición de código
```

La diferencia es enorme en proyectos con muchas dependencias: el `npm ci` puede tardar 30–60 segundos. Con el orden correcto, ese paso se saltea en todos los builds donde solo cambia el código.

### Verificar el resultado

Antes de publicar una imagen optimizada, verifica tres cosas:

```bash
# Tamaño real de la imagen
docker image ls nombre:tag

# Capas y comandos que generaron cada una
docker image history nombre:tag

# Usuario que corre el proceso principal
docker run --rm nombre:tag whoami
docker run --rm nombre:tag id
```

## Comandos de la Sesión

```bash
# Construir con nombre de etapa
# (FROM ... AS nombre en el Dockerfile)
docker build -t nombre:tag .

# Construir solo hasta una etapa específica
docker build --target builder -t nombre:debug .

# Comparar tamaños
docker image ls nombre

# Ver capas y comandos
docker image history nombre:tag
docker image history --no-trunc nombre:tag

# Verificar usuario del proceso
docker run --rm nombre:tag whoami
docker run --rm nombre:tag id

# Inspeccionar configuración de la imagen
docker image inspect nombre:tag
docker image inspect nombre:tag --format '{{.Config.User}}'

# Medir tiempo de build (primera vez vs rebuild)
time docker build --no-cache -t nombre:tag .
time docker build -t nombre:tag .

# Build con argumento de etapa
docker build --target etapa-nombre -t nombre:debug .

# Ver tamaño de capas individuales
docker image history --format 'table {{.Size}}\t{{.CreatedBy}}' nombre:tag
```

## Validación General

- [ ] `docker image ls` muestra la imagen multi-stage con tamaño notablemente menor que la single-stage.
- [ ] `docker image history` de la imagen final no muestra capas del compilador ni de las dependencias de build.
- [ ] `docker run --rm lab04-app:noroot whoami` devuelve un usuario distinto de `root`.
- [ ] `docker run --rm lab04-app:noroot id` devuelve un UID mayor que 0.
- [ ] El rebuild sin cambios de código usa caché y termina en menos de 5 segundos.
- [ ] El rebuild cambiando solo el código fuente no reinstala dependencias.

## Limpieza

```bash
docker rm -f $(docker ps -aq --filter "name=lab-") 2>/dev/null || true
docker image rm \
  lab04-app:single lab04-app:multistage \
  lab04-app:root lab04-app:noroot \
  lab04-cache:v1 lab04-cache:v2 lab04-cache:v3 \
  2>/dev/null || true
docker image prune -f
```

Verifica:

```bash
docker ps -a --filter "name=lab-"
docker image ls | grep lab04
```

## Desafío Opcional

Toma la imagen que publicaste en el lab 04 de la sesión 3 y optimízala: convierte su `Dockerfile` a multi-stage, agrega un usuario no root y elige la imagen base más pequeña que soporte tu aplicación. Compara el tamaño antes y después, y publica la versión optimizada en Docker Hub con el tag `:2.0`.

Ver instrucciones completas en [tareas/desafio-opcional.md](tareas/desafio-opcional.md).

## Cierre

Antes de cerrar la sesión, verifica que puedes responder:

- [ ] ¿Qué problema resuelve el multi-stage build que no resuelve un único `Dockerfile` con múltiples `RUN`?
- [ ] ¿Qué ocurre con las capas de la etapa `builder` en la imagen final?
- [ ] ¿Cuándo usarías `scratch` en lugar de `alpine`? ¿Cuál es la restricción?
- [ ] ¿Por qué el proceso debería correr como usuario no root?
- [ ] Si cambias solo una línea de código en tu aplicación Node.js, ¿qué capas se invalidan con el orden correcto de instrucciones?
- [ ] ¿Cómo verificas en tiempo de ejecución que el proceso no corre como root?

## Preparación para la Siguiente Sesión

En la sesión 5 comenzarás a orquestar múltiples contenedores con Docker Compose. Asegúrate de tener `docker compose version` respondiendo con v2 y al menos una imagen propia construida con la que experimentar.
