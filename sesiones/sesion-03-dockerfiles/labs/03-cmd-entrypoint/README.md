# Lab 03: CMD vs ENTRYPOINT

## Objetivo

Observar el comportamiento real de `CMD` y `ENTRYPOINT` al arrancar contenedores con y sin argumentos en `docker run`, y entender cuándo usar cada uno.

## Requisitos

- Docker funcionando (`docker version` responde sin error).
- Familiaridad básica con `docker run` y `docker build`.

## Paso a paso

### 1. Crear el directorio de trabajo

```bash
mkdir -p ~/workspace/lab03-arranque
cd ~/workspace/lab03-arranque
```

### 2. Imagen con solo CMD

Construye una imagen cuyo proceso por defecto sea imprimir un saludo.

```bash
cat > Dockerfile.cmd <<'EOF'
FROM alpine:3.21
# CMD define el comando completo. docker run puede reemplazarlo.
CMD ["echo", "Hola desde CMD"]
EOF

docker build -f Dockerfile.cmd -t lab03-saludo:cmd .
```

Prueba los tres escenarios:

```bash
# Escenario A: sin argumentos en docker run -> se ejecuta CMD
docker run --rm lab03-saludo:cmd

# Escenario B: con argumentos en docker run -> CMD se reemplaza
docker run --rm lab03-saludo:cmd echo "CMD reemplazado"

# Escenario C: comando completamente distinto -> CMD se reemplaza
docker run --rm lab03-saludo:cmd ls /
```

Observa: en el escenario B y C, el `CMD` del Dockerfile fue ignorado por completo.

### 3. Imagen con solo ENTRYPOINT

```bash
cat > Dockerfile.ep <<'EOF'
FROM alpine:3.21
# ENTRYPOINT fija el ejecutable. Los argumentos de docker run se le pasan.
ENTRYPOINT ["echo"]
EOF

docker build -f Dockerfile.ep -t lab03-saludo:entrypoint .
```

Prueba los escenarios equivalentes:

```bash
# Escenario A: sin argumentos -> ENTRYPOINT sin parámetros
docker run --rm lab03-saludo:entrypoint

# Escenario B: con argumentos -> se pasan a ENTRYPOINT como parámetros
docker run --rm lab03-saludo:entrypoint "Hola desde ENTRYPOINT con argumento"

# Escenario C: intentar reemplazar el ejecutable (requiere --entrypoint)
docker run --rm --entrypoint ls lab03-saludo:entrypoint /
```

Observa: en el escenario B, el argumento se pasó a `echo`. Para reemplazar el ejecutable es necesario `--entrypoint` explícito.

### 4. Imagen con ENTRYPOINT y CMD combinados

La combinación es el patrón más flexible: ENTRYPOINT fija el ejecutable y CMD provee los argumentos por defecto, que el usuario puede sobrescribir.

```bash
cat > Dockerfile.combo <<'EOF'
FROM alpine:3.21
# ENTRYPOINT fija el ejecutable
ENTRYPOINT ["echo"]
# CMD provee los argumentos por defecto
CMD ["mensaje por defecto"]
EOF

docker build -f Dockerfile.combo -t lab03-saludo:combo .
```

Prueba los escenarios:

```bash
# Escenario A: sin argumentos -> ENTRYPOINT + CMD por defecto
docker run --rm lab03-saludo:combo

# Escenario B: con argumentos -> CMD se reemplaza, ENTRYPOINT se mantiene
docker run --rm lab03-saludo:combo "mensaje personalizado"
```

### 5. Un caso práctico: script de entrada

En imágenes reales, `ENTRYPOINT` suele apuntar a un script que inicializa la aplicación, y `CMD` define los argumentos o subcomandos por defecto.

```bash
cat > entrypoint.sh <<'EOF'
#!/bin/sh
echo "Iniciando aplicación..."
echo "Argumentos recibidos: $@"
exec "$@"
EOF
chmod +x entrypoint.sh

cat > Dockerfile.script <<'EOF'
FROM alpine:3.21
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["echo", "sin subcomando"]
EOF

docker build -f Dockerfile.script -t lab03-saludo:script .

# Usar el CMD por defecto
docker run --rm lab03-saludo:script

# Sobreescribir CMD con un subcomando real
docker run --rm lab03-saludo:script ls /etc
```

### 6. Forma shell vs forma exec

Construye dos imágenes para comparar cuál es PID 1 en cada caso:

```bash
cat > Dockerfile.shell <<'EOF'
FROM alpine:3.21
# Forma shell: el proceso real es /bin/sh -c "sleep 30"
CMD sleep 30
EOF

cat > Dockerfile.exec <<'EOF'
FROM alpine:3.21
# Forma exec: el proceso real es sleep
CMD ["sleep", "30"]
EOF

docker build -f Dockerfile.shell -t lab03-saludo:shell .
docker build -f Dockerfile.exec  -t lab03-saludo:exec .

# Ver PID 1 en cada imagen
docker run -d --name lab03-shell lab03-saludo:shell
docker run -d --name lab03-exec  lab03-saludo:exec
docker exec lab03-shell ps aux
docker exec lab03-exec  ps aux
```

En `lab03-shell`, PID 1 es `/bin/sh`. En `lab03-exec`, PID 1 es `sleep`. Esto importa al enviar señales: `docker stop` envía `SIGTERM` a PID 1. Si PID 1 es el shell, la señal puede no llegar a la aplicación.

## Validación

- [ ] `docker run --rm lab03-saludo:cmd` imprime `Hola desde CMD`.
- [ ] `docker run --rm lab03-saludo:cmd echo "reemplazado"` imprime `reemplazado` (CMD sobreescrito).
- [ ] `docker run --rm lab03-saludo:entrypoint "texto"` imprime `texto` (argumento pasado a ENTRYPOINT).
- [ ] `docker run --rm lab03-saludo:combo` imprime el mensaje por defecto.
- [ ] `docker run --rm lab03-saludo:combo "otro mensaje"` imprime `otro mensaje`.
- [ ] `docker exec lab03-exec ps aux` muestra `sleep` como PID 1.
- [ ] `docker exec lab03-shell ps aux` muestra `/bin/sh` como PID 1.

## Limpieza

```bash
docker rm -f lab03-shell lab03-exec 2>/dev/null || true
docker image rm \
  lab03-saludo:cmd \
  lab03-saludo:entrypoint \
  lab03-saludo:combo \
  lab03-saludo:script \
  lab03-saludo:shell \
  lab03-saludo:exec \
  2>/dev/null || true
rm -rf ~/workspace/lab03-arranque
```

Verifica:

```bash
docker ps -a --filter "name=lab03-"
docker image ls lab03-saludo
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| `docker run` ignora los argumentos y ejecuta CMD de todas formas | La imagen usa `ENTRYPOINT` en forma shell, que envuelve en `sh -c` y no recibe argumentos | Reescribir `ENTRYPOINT` en forma exec: `ENTRYPOINT ["ejecutable"]` |
| `docker stop` tarda 10 segundos en detener el contenedor | PID 1 es el shell (forma shell) y no propaga `SIGTERM` | Cambiar a forma exec en el `Dockerfile` |
| `exec: "entrypoint.sh": permission denied` | El script no tiene permisos de ejecución en la imagen | Agregar `RUN chmod +x /entrypoint.sh` en el `Dockerfile` o verificar `chmod +x` antes del build |
