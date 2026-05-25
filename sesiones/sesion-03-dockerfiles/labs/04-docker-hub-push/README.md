# Lab 04: Publicar en Docker Hub

## Objetivo

Etiquetar una imagen con el prefijo de tu usuario de Docker Hub, publicarla con `docker push` y verificar que cualquier persona puede descargarla y ejecutarla.

## Requisitos

- Docker funcionando (`docker version` responde sin error).
- Cuenta activa en [hub.docker.com](https://hub.docker.com/). Si no tienes una, créala antes de comenzar.
- Haber completado el lab 01 (imagen `lab01-web:1.0`) o tener cualquier imagen local construida.

## Paso a paso

### 1. Crear el directorio de trabajo

```bash
mkdir -p ~/workspace/lab04-hub
cd ~/workspace/lab04-hub
```

### 2. Construir la imagen que publicarás

Construye una imagen sencilla pero identificable como tuya:

```bash
cat > index.html <<'EOF'
<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><title>Sesión 3</title></head>
<body>
  <h1>Publicado desde el Lab 04</h1>
  <p>Sesión 3 - Docker &amp; Kubernetes para Desarrolladores</p>
</body>
</html>
EOF

cat > Dockerfile <<'EOF'
FROM nginx:1.27-alpine
LABEL descripcion="Lab 04 - Publicacion en Docker Hub"
WORKDIR /usr/share/nginx/html
COPY index.html .
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

docker build -t sesion03-web:1.0 .
```

### 3. Verificar que la imagen funciona localmente

Antes de publicar, confirma que el contenedor arranca correctamente:

```bash
docker run -d --name lab04-verificacion -p 8084:80 sesion03-web:1.0
curl http://localhost:8084
docker rm -f lab04-verificacion
```

### 4. Etiquetar la imagen con tu usuario de Docker Hub

El nombre de una imagen en Docker Hub sigue el formato `usuario/repositorio:tag`. Reemplaza `TU_USUARIO` con tu nombre de usuario real en Docker Hub.

```bash
docker tag sesion03-web:1.0 TU_USUARIO/sesion03-web:1.0
```

Verifica que el tag existe:

```bash
docker image ls | grep sesion03-web
```

Debes ver dos entradas: `sesion03-web:1.0` y `TU_USUARIO/sesion03-web:1.0`. Ambas apuntan a la misma imagen (mismo IMAGE ID); el tag es solo un alias.

### 5. Iniciar sesión en Docker Hub

```bash
docker login
```

Docker pedirá tu nombre de usuario y contraseña. Si tienes autenticación de dos factores activa, usa un Personal Access Token (PAT) en lugar de la contraseña. Puedes crear uno en `hub.docker.com > Account Settings > Personal Access Tokens`.

### 6. Publicar la imagen

```bash
docker push TU_USUARIO/sesion03-web:1.0
```

Docker sube solo las capas que Docker Hub no tiene todavía. La primera vez sube todo; en pushes posteriores de la misma imagen base, solo las capas nuevas.

### 7. Verificar la publicación en Docker Hub

Abre `https://hub.docker.com/r/TU_USUARIO/sesion03-web` en el navegador. Debes ver el repositorio creado automáticamente con el tag `1.0`.

También puedes verificar desde la terminal:

```bash
docker search TU_USUARIO/sesion03-web
```

### 8. Probar el pull desde cero

Simula lo que haría otra persona: elimina la imagen local y descárgala desde Docker Hub.

```bash
docker image rm TU_USUARIO/sesion03-web:1.0 sesion03-web:1.0

# Descarga y ejecuta directamente desde Docker Hub
docker run -d --name lab04-desde-hub -p 8084:80 TU_USUARIO/sesion03-web:1.0
curl http://localhost:8084
```

Si ves el HTML, la imagen está correctamente publicada y funciona desde el registro.

### 9. Publicar un segundo tag

Es común publicar la misma imagen con múltiples tags: uno de versión y uno de alias (`latest` o `stable`). Nota: en este curso evitamos `latest` salvo para demostrar por qué hay que evitarlo; puedes usar un alias descriptivo en su lugar.

```bash
docker tag TU_USUARIO/sesion03-web:1.0 TU_USUARIO/sesion03-web:alpine
docker push TU_USUARIO/sesion03-web:alpine
```

### 10. Cerrar sesión

Una buena práctica es cerrar sesión en máquinas compartidas:

```bash
docker logout
```

## Validación

- [ ] `docker image ls | grep sesion03-web` muestra el tag con tu usuario de Docker Hub.
- [ ] `docker push TU_USUARIO/sesion03-web:1.0` completó sin errores.
- [ ] La URL `https://hub.docker.com/r/TU_USUARIO/sesion03-web` muestra el repositorio con el tag `1.0`.
- [ ] Después de eliminar la imagen local, `docker run TU_USUARIO/sesion03-web:1.0` la descarga y el contenedor responde en el puerto.

## Limpieza

```bash
docker rm -f lab04-desde-hub 2>/dev/null || true
docker image rm \
  TU_USUARIO/sesion03-web:1.0 \
  TU_USUARIO/sesion03-web:alpine \
  sesion03-web:1.0 \
  2>/dev/null || true
rm -rf ~/workspace/lab04-hub
```

Verifica:

```bash
docker ps -a --filter "name=lab04-"
docker image ls | grep sesion03-web
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| `denied: requested access to the resource is denied` | La imagen no tiene el prefijo del usuario o la sesión expiró | Verificar el tag con `docker image ls` y volver a ejecutar `docker login` |
| `unauthorized: authentication required` | No hay sesión activa | Ejecutar `docker login` antes de `docker push` |
| `error parsing HTTP 403` con Personal Access Token | El token no tiene el permiso `Read & Write` en Docker Hub | Crear un nuevo PAT con los permisos correctos en `hub.docker.com > Account Settings` |
| El repositorio no aparece en Docker Hub | Push exitoso pero el navegador muestra caché antigua | Refrescar la página o esperar unos segundos y volver a intentarlo |
