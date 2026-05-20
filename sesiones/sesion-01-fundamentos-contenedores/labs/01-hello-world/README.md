# Lab 01: Hello World

## Objetivo

Validar la instalación de Docker ejecutando el primer contenedor y observar el flujo completo desde la descarga de una imagen hasta la finalización del proceso.

## Requisitos

- Docker Desktop o Docker Engine instalado y en ejecución.
- Terminal Linux o WSL con acceso a Docker.

## Paso a paso

### 1. Verificar que Docker está listo

```bash
docker --version
docker info
```

`docker info` debe responder sin errores de conexión. Si falla, inicia Docker Desktop o el servicio Docker antes de continuar.

### 2. Ejecutar `hello-world`

```bash
docker run --name lab-hello hello-world
```

Docker busca la imagen localmente. Como no existe, la descarga desde Docker Hub, crea un contenedor y ejecuta el proceso definido en la imagen.

Salida esperada (fragmento):

```text
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

### 3. Observar el estado del contenedor

```bash
docker ps -a --filter "name=lab-hello"
```

El contenedor aparece con estado `Exited (0)`. Finalizó porque su proceso principal terminó.

### 4. Revisar los logs

```bash
docker logs lab-hello
```

Muestra la misma salida del paso anterior. Los logs persisten mientras el contenedor exista.

### 5. Comparar: contenedor efímero vs contenedor persistente

```bash
docker run --rm hello-world
docker ps -a --filter "name=lab-hello"
```

Con `--rm`, Docker elimina el contenedor automáticamente al terminar. Sin `--rm`, el contenedor queda disponible para inspección posterior.

## Validación

```bash
docker ps -a --filter "name=lab-hello"
docker logs lab-hello
```

La práctica está completa si:

- [ ] `lab-hello` existe con estado `Exited (0)`.
- [ ] `docker logs lab-hello` muestra el mensaje de bienvenida de Docker.
- [ ] Puedes explicar por qué el contenedor terminó solo.

## Limpieza

```bash
docker rm lab-hello
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| `Cannot connect to the Docker daemon` | Docker no está en ejecución | Iniciar Docker Desktop o `sudo systemctl start docker` |
| `permission denied` | Usuario no tiene acceso al socket de Docker | `sudo usermod -aG docker $USER && newgrp docker` |
| `The container name "/lab-hello" is already in use` | Ya existe un contenedor con ese nombre | `docker rm lab-hello` y volver a ejecutar |
