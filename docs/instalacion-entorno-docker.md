# Instalación del Entorno Docker

## Objetivo

Preparar el entorno de trabajo para el bloque Docker del curso usando una terminal Linux como flujo principal.

En Windows, el estándar del curso es **WSL 2 con Ubuntu 24.04**. Docker Desktop se usa como motor de Docker y como interfaz gráfica de apoyo, pero los comandos del curso se ejecutan desde Ubuntu/WSL.

## Alcance

Esta guía cubre únicamente el entorno Docker:

- Docker Engine o Docker Desktop como motor de contenedores.
- Docker CLI desde terminal Linux.
- Docker Compose v2 con el comando `docker compose`.
- Validación con contenedores reales.

Kubernetes se prepara en el bloque Kubernetes del curso con minikube o MicroK8s. No uses el Kubernetes integrado de Docker Desktop como entorno del curso.

## Ruta Recomendada en Windows

### 1. Instalar WSL 2 con Ubuntu 24.04

Los siguientes comandos se ejecutan una sola vez desde Windows para preparar WSL. Después de esta instalación, las prácticas del curso se ejecutan desde Ubuntu/WSL.

Abre una terminal de Windows con permisos de administrador y ejecuta:

```text
wsl --install -d Ubuntu-24.04
```

Si ya tienes WSL instalado, revisa las distribuciones disponibles:

```text
wsl --list --online
```

Verifica que Ubuntu use WSL 2:

```text
wsl --list --verbose
```

Si la distribución aparece con versión 1, conviértela a WSL 2:

```text
wsl --set-version Ubuntu-24.04 2
```

También puedes dejar WSL 2 como valor por defecto para nuevas distribuciones:

```text
wsl --set-default-version 2
```

### 2. Preparar Ubuntu

Abre Ubuntu 24.04 y actualiza los paquetes base:

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y ca-certificates curl git
```

Trabaja dentro del sistema de archivos de Linux, no bajo `/mnt/c`, para evitar problemas de rendimiento con montajes y notificaciones de archivos:

```bash
mkdir -p ~/workspace
cd ~/workspace
```

### 3. Instalar Docker Desktop en Windows

Instala la versión actual de Docker Desktop para Windows desde el sitio oficial de Docker.

Durante la instalación o después de abrir Docker Desktop:

1. Activa el backend de WSL 2.
2. En `Settings > Resources > WSL Integration`, habilita la integración con `Ubuntu-24.04`.
3. Mantén deshabilitado Kubernetes en Docker Desktop para este curso.

No instales Docker Engine directamente dentro de Ubuntu/WSL si usarás Docker Desktop como motor. Tener ambos motores en el mismo flujo suele generar conflictos de contexto, socket y versiones.

### 4. Validar Docker desde Ubuntu/WSL

Cierra y vuelve a abrir la terminal de Ubuntu. Luego ejecuta:

```bash
docker version
docker compose version
docker run --rm hello-world
```

Resultado esperado:

- `docker version` muestra cliente y servidor.
- `docker compose version` muestra Compose v2.
- `hello-world` descarga una imagen y ejecuta un contenedor de validación.

## Ruta Alternativa en Linux Nativo

En Linux nativo se recomienda instalar Docker Engine desde el repositorio oficial de Docker, no desde paquetes antiguos de la distribución.

### 1. Preparar el repositorio oficial

```bash
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

Agrega el repositorio:

```bash
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```

Instala Docker Engine y los plugins modernos:

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 2. Validar el servicio

```bash
sudo systemctl status docker
sudo docker run --rm hello-world
```

### 3. Ejecutar Docker sin `sudo`

```bash
sudo usermod -aG docker "$USER"
newgrp docker
docker run --rm hello-world
```

Si el equipo pertenece a una organización, valida esta configuración con el administrador antes de modificar grupos del sistema.

## Ruta Secundaria en macOS

Instala Docker Desktop para macOS y ejecuta las prácticas desde una terminal Unix.

Valida:

```bash
docker version
docker compose version
docker run --rm hello-world
```

Kubernetes de Docker Desktop debe permanecer deshabilitado para mantener el mismo flujo del curso que en Windows y Linux.

## Validación Final del Entorno

Ejecuta desde la terminal donde harás el curso:

```bash
docker version
docker compose version
docker run --rm hello-world
docker run -d --name entorno-docker-test -p 8080:80 nginx:alpine
curl -I http://localhost:8080
docker rm -f entorno-docker-test
```

El entorno está listo si:

- Docker responde sin errores de conexión.
- Compose responde con versión 2.x.
- El contenedor `hello-world` se ejecuta correctamente.
- Nginx responde por `http://localhost:8080`.
- El contenedor de prueba se elimina al final.

## Criterios del Curso

Usaremos:

- Terminal Linux como entorno principal.
- `docker compose`, no `docker-compose`.
- Archivos `compose.yaml`.
- Imágenes con tags explícitos cuando corresponda.
- Kubernetes local separado del Kubernetes integrado de Docker Desktop.

No usaremos:

- PowerShell o CMD para los laboratorios, salvo indicación explícita de preparación del entorno.
- Docker Toolbox.
- Kubernetes de Docker Desktop como cluster del curso.
- Paquetes antiguos como `docker.io` para instalaciones nuevas de Linux.
- La propiedad superior `version:` en archivos Compose nuevos.

## Problemas Frecuentes

### Docker no responde desde Ubuntu/WSL

Verifica que Docker Desktop esté abierto y que la integración con `Ubuntu-24.04` esté habilitada en `Settings > Resources > WSL Integration`.

Después, reinicia la terminal de Ubuntu y prueba:

```bash
docker version
```

### La distribución está en WSL 1

Desde Windows:

```text
wsl --list --verbose
wsl --set-version Ubuntu-24.04 2
```

### `docker: command not found` en Ubuntu/WSL

La integración de Docker Desktop con la distribución no está habilitada o la terminal se abrió antes de activar la integración.

Acción:

1. Habilita `Ubuntu-24.04` en `Settings > Resources > WSL Integration`.
2. Cierra la terminal de Ubuntu.
3. Abre una terminal nueva.
4. Ejecuta `docker version`.

### Permiso denegado en Linux nativo

```text
permission denied while trying to connect to the Docker daemon socket
```

Acción:

```bash
sudo usermod -aG docker "$USER"
newgrp docker
docker version
```

### El puerto 8080 está ocupado

Usa otro puerto local para validar:

```bash
docker run -d --name entorno-docker-test -p 8081:80 nginx:alpine
curl -I http://localhost:8081
docker rm -f entorno-docker-test
```

### El repositorio está bajo `/mnt/c`

Mover el proyecto al sistema de archivos de Linux mejora el rendimiento de montajes, builds y herramientas de desarrollo:

```bash
mkdir -p ~/workspace
```

Clona o copia allí tus proyectos de trabajo.

## Referencias Oficiales

- Docker Desktop con WSL 2: <https://docs.docker.com/desktop/features/wsl/>
- Buenas prácticas de Docker Desktop con WSL 2: <https://docs.docker.com/desktop/features/wsl/best-practices/>
- Docker Engine en Ubuntu: <https://docs.docker.com/engine/install/ubuntu/>
- Instalación de WSL: <https://learn.microsoft.com/windows/wsl/install>
- Instalación de Ubuntu 24.04 en WSL: <https://documentation.ubuntu.com/wsl/latest/howto/install-ubuntu-wsl2/>
