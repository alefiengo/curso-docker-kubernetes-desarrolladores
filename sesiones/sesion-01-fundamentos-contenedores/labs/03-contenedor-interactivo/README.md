# Lab 03: Contenedor interactivo

## Objetivo

Abrir una sesión de shell dentro de un contenedor, explorar su sistema de archivos y procesos, y comprender la diferencia entre `docker run -it` y `docker exec -it`.

## Requisitos

- Docker en ejecución.
- Conexión a internet para descargar la imagen base de Ubuntu.

## Paso a paso

### 1. Iniciar un contenedor interactivo

```bash
docker run -it --name lab-shell ubuntu:24.04 bash
```

Desglose:

| Parte | Significado |
|---|---|
| `-i` | Mantiene la entrada estándar abierta para poder escribir comandos |
| `-t` | Asigna una pseudoterminal para que el prompt se comporte como una terminal real |
| `--name lab-shell` | Nombre fijo para el contenedor |
| `ubuntu:24.04` | Imagen oficial de Ubuntu 24.04 |
| `bash` | Proceso principal que se ejecuta al iniciar el contenedor |

El prompt cambia a algo similar a `root@a1b2c3d4e5f6:/#`. Estás dentro del contenedor.

### 2. Explorar el aislamiento

Dentro del contenedor:

```bash
cat /etc/os-release
hostname
ls /
ps aux
```

Puntos a observar:

- `cat /etc/os-release` muestra Ubuntu 24.04, independientemente del sistema anfitrión.
- `hostname` devuelve el ID del contenedor, no el nombre del equipo.
- `ps aux` lista solo los procesos del contenedor, no los del sistema anfitrión.
- El kernel mostrado por `uname -r` es el mismo que el del anfitrión: los contenedores comparten el kernel.

### 3. Salir del contenedor

```bash
exit
```

El contenedor se detiene porque `bash` era el proceso principal. Al finalizar el proceso principal, el contenedor pasa a estado `Exited`.

### 4. Verificar el estado desde el anfitrión

```bash
docker ps -a --filter "name=lab-shell"
```

El contenedor existe con estado `Exited (0)`.

### 5. Diferencia entre `docker run -it` y `docker exec -it`

`docker run -it` crea un contenedor nuevo y ejecuta el proceso indicado como proceso principal. Al salir, el contenedor se detiene.

`docker exec -it` se conecta a un contenedor ya en ejecución y lanza un proceso adicional. Al salir, el contenedor sigue corriendo.

Ejemplo práctico con Nginx:

```bash
docker run -d --name lab-exec-demo -p 8082:80 nginx:alpine
docker exec -it lab-exec-demo sh
```

Dentro del contenedor Nginx:

```bash
ls /usr/share/nginx/html/
cat /etc/nginx/nginx.conf
exit
```

Verificar que Nginx sigue corriendo después de salir:

```bash
docker ps --filter "name=lab-exec-demo"
```

Limpieza del contenedor de demostración:

```bash
docker rm -f lab-exec-demo
```

## Validación

```bash
docker ps -a --filter "name=lab-shell"
```

La práctica está completa si:

- [ ] `lab-shell` existe con estado `Exited (0)`.
- [ ] Puedes explicar qué ocurre con el contenedor cuando su proceso principal termina.
- [ ] Puedes explicar la diferencia entre `docker run -it` y `docker exec -it`.

## Limpieza

```bash
docker rm lab-shell
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| El contenedor se detiene inmediatamente al hacer `docker start lab-shell` | `bash` necesita una terminal interactiva para seguir ejecutándose | Usar `docker start -ai lab-shell` para reconectarse |
| `the input device is not a TTY` | El comando se ejecuta en un contexto sin terminal (script, CI) | Usar solo `-i` sin `-t`: `docker run -i ubuntu:24.04 bash` |
| `The container name "/lab-shell" is already in use` | Ya existe un contenedor con ese nombre | `docker rm lab-shell` y volver a ejecutar |
