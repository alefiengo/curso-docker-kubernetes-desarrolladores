# Lab 02: Usuario No Root

## Objetivo

Agregar un usuario sin privilegios a la imagen del lab anterior y verificar que el proceso principal corre con ese usuario en lugar de root.

## Requisitos

- Haber completado el lab 01 de esta sesión.
- La imagen `lab04-app:multistage` construida en el lab 01.
- Docker funcionando.

## Paso a paso

### Parte 1: verificar el problema

Antes de corregir, verifica con qué usuario corre la imagen actual.

**1. Comprobar el usuario por defecto:**

```bash
docker run --rm lab04-app:multistage id
```

La salida debería mostrar `uid=0(root) gid=0(root) groups=0(root)`. Esto significa que el proceso principal corre como root dentro del contenedor.

**2. Verificar en la configuración de la imagen:**

```bash
docker image inspect lab04-app:multistage --format '{{.Config.User}}'
```

La salida estará vacía, lo que confirma que no se ha definido ningún usuario.

### Parte 2: imagen con usuario root explícito (para comparar)

**3. Ir al directorio del lab 01:**

```bash
cd ~/labs/lab04-01-multistage
```

Reutilizarás el código `main.go` y `go.mod` del lab anterior.

**4. Construir con tag `root` para conservar la referencia:**

```bash
docker build -f Dockerfile.multi -t lab04-app:root .
```

### Parte 3: agregar usuario no root

**5. Crear el Dockerfile con usuario no root:**

La diferencia respecto al `Dockerfile.multi` anterior está en tres líneas:
- `RUN addgroup -S appgroup && adduser -S appuser -G appgroup` crea el grupo y el usuario del sistema.
- `COPY --chown=appuser:appgroup` asigna la propiedad del binario en el momento de la copia.
- `USER appuser` designa el usuario para las instrucciones siguientes y para el proceso final.

```bash
cat > Dockerfile.noroot << 'EOF'
# Etapa 1: compilación
FROM golang:1.22-alpine AS builder
WORKDIR /src
COPY go.mod ./
COPY main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/servidor .

# Etapa 2: imagen final con usuario no root
FROM alpine:3.21

# Crear grupo y usuario sin privilegios antes de copiar archivos
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Asignar la propiedad del binario al usuario de la app en el mismo COPY
COPY --from=builder --chown=appuser:appgroup /app/servidor .

EXPOSE 8080

USER appuser

CMD ["./servidor"]
EOF
```

**6. Construir la imagen con usuario no root:**

```bash
docker build -f Dockerfile.noroot -t lab04-app:noroot .
```

### Parte 4: verificar el resultado

**7. Comprobar el usuario con el que corre el proceso:**

```bash
docker run --rm lab04-app:noroot id
```

La salida debe mostrar un UID diferente de 0, por ejemplo:
`uid=100(appuser) gid=101(appgroup)`.

**8. Verificar en la configuración de la imagen:**

```bash
docker image inspect lab04-app:noroot --format '{{.Config.User}}'
```

Ahora debe devolver `appuser`.

**9. Verificar que la aplicación sigue funcionando:**

```bash
docker run -d --name lab-noroot -p 8081:8080 lab04-app:noroot
sleep 1
curl http://localhost:8081
```

La aplicación responde igual que antes, pero ahora el proceso corre sin privilegios de root.

**10. Comparar los usuarios de ambas imágenes:**

```bash
echo "Imagen con root:"
docker run --rm lab04-app:root id

echo "Imagen sin root:"
docker run --rm lab04-app:noroot id
```

**11. Verificar el tamaño de ambas imágenes:**

```bash
docker image ls lab04-app
```

La imagen `noroot` tiene prácticamente el mismo tamaño que `multistage` y `root`. Agregar el usuario no añade espacio significativo.

### Parte 5: intentar una operación privilegiada

Para ilustrar el aislamiento, intenta escribir en un directorio del sistema desde el contenedor no root.

**12. Intentar escribir en /etc desde el contenedor:**

```bash
docker run --rm lab04-app:noroot sh -c "echo test > /etc/test.txt" 2>&1 || echo "Permiso denegado — usuario no root no puede escribir en /etc"
```

La operación falla porque el usuario `appuser` no tiene permisos para escribir fuera de `/app`.

### Parte 6: imagen con Debian slim (variante con useradd)

En imágenes basadas en Debian o Ubuntu, los comandos son diferentes. El patrón es el mismo, pero la sintaxis cambia.

**13. Crear un Dockerfile con python:3.12-slim para ver el patrón Debian:**

```bash
cat > Dockerfile.slim << 'EOF'
FROM python:3.12-slim
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
WORKDIR /app
COPY --chown=appuser:appgroup . .
USER appuser
CMD ["python", "-c", "import http.server; http.server.test(HandlerClass=http.server.SimpleHTTPRequestHandler, port=8080)"]
EOF
```

```bash
docker build -f Dockerfile.slim -t lab04-app:slim .
docker run --rm lab04-app:slim id
```

Observa que la misma lógica (`groupadd -r`, `useradd -r`) funciona en el ecosistema Debian.

## Validación

- [ ] `docker run --rm lab04-app:noroot id` devuelve un UID mayor que 0.
- [ ] `docker run --rm lab04-app:root id` devuelve `uid=0(root)`.
- [ ] `docker image inspect lab04-app:noroot --format '{{.Config.User}}'` devuelve `appuser`.
- [ ] `curl http://localhost:8081` devuelve la respuesta del servidor.
- [ ] El intento de escribir en `/etc` desde el contenedor no root falla con permiso denegado.
- [ ] `docker image ls lab04-app` muestra que `noroot` y `root` tienen tamaños similares.

## Limpieza

```bash
docker rm -f lab-noroot 2>/dev/null || true
docker image rm lab04-app:root lab04-app:noroot lab04-app:slim 2>/dev/null || true
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| `adduser: user 'appuser' in use` | La imagen base ya tiene un usuario con ese nombre | Elige otro nombre de usuario o verifica con `docker run --rm alpine:3.21 cat /etc/passwd` |
| `permission denied` al ejecutar `./servidor` | El binario no tiene permisos de ejecución para `appuser` | Usa `COPY --chown=appuser:appgroup` o agrega `RUN chmod 755 ./servidor` antes de `USER` |
| `id: command not found` | La imagen no tiene el binario `id` | Usa `whoami` en su lugar; en `scratch` o distroless no existe ninguna herramienta de shell |
| El servidor no responde en el puerto 8081 | El contenedor del lab anterior ocupa el 8081 | Detén el contenedor anterior con `docker rm -f lab-noroot` y recrea |
| `useradd: command not found` en Alpine | Alpine usa `adduser`, no `useradd` | En Alpine usa `addgroup -S` y `adduser -S`; en Debian/Ubuntu usa `groupadd -r` y `useradd -r` |
