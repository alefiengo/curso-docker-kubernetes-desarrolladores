# Lab 01: Multi-stage Build

## Objetivo

Construir la misma aplicación con un `Dockerfile` single-stage y uno multi-stage, comparar los tamaños resultantes y verificar que la imagen final no contiene herramientas de build.

## Requisitos

- Docker funcionando (`docker version` responde sin errores).
- Haber completado los labs de la sesión 3 (sabes construir imágenes con `docker build`).
- Conexión a internet para descargar las imágenes base.

## Paso a paso

### Parte 1: preparar la aplicación de muestra

Usarás una pequeña aplicación Go que responde a peticiones HTTP. Go es ideal para demostrar multi-stage porque el compilador y el binario tienen tamaños muy distintos.

**1. Crear el directorio de trabajo:**

```bash
mkdir -p ~/labs/lab04-01-multistage && cd ~/labs/lab04-01-multistage
```

**2. Crear la aplicación Go:**

El siguiente comando crea el archivo fuente de la aplicación con un servidor HTTP mínimo.

```bash
cat > main.go << 'EOF'
package main

import (
	"fmt"
	"net/http"
	"os"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		hostname, _ := os.Hostname()
		fmt.Fprintf(w, "Sesion 4 - Multi-stage build\nHost: %s\n", hostname)
	})
	fmt.Println("Servidor iniciando en :8080")
	http.ListenAndServe(":8080", nil)
}
EOF
```

**3. Crear el módulo Go:**

```bash
cat > go.mod << 'EOF'
module lab04/servidor

go 1.22
EOF
```

### Parte 2: Dockerfile single-stage

El Dockerfile single-stage compila y empaqueta todo en una sola imagen. El resultado incluye el compilador, la caché de módulos y el código fuente, aunque ninguno de esos archivos es necesario para ejecutar el binario.

**4. Crear el Dockerfile single-stage:**

```bash
cat > Dockerfile.single << 'EOF'
FROM golang:1.22-alpine
WORKDIR /src
COPY go.mod ./
COPY main.go ./
RUN go build -o /app/servidor .
EXPOSE 8080
CMD ["/app/servidor"]
EOF
```

**5. Construir la imagen single-stage:**

```bash
docker build -f Dockerfile.single -t lab04-app:single .
```

**6. Registrar el tamaño:**

```bash
docker image ls lab04-app:single
```

Anota el valor de la columna `SIZE`. Con `golang:1.22-alpine` como base, la imagen tendrá aproximadamente 250–300 MB.

### Parte 3: Dockerfile multi-stage

El Dockerfile multi-stage usa dos etapas. La primera (`builder`) compila el binario. La segunda copia solo el binario compilado en una imagen base mínima.

**7. Crear el Dockerfile multi-stage:**

```bash
cat > Dockerfile.multi << 'EOF'
# Etapa 1: compilación
FROM golang:1.22-alpine AS builder
WORKDIR /src
COPY go.mod ./
COPY main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/servidor .

# Etapa 2: imagen final
FROM alpine:3.21
WORKDIR /app
COPY --from=builder /app/servidor .
EXPOSE 8080
CMD ["./servidor"]
EOF
```

La clave está en `CGO_ENABLED=0`: produce un binario estático que no depende de librerías del sistema. `COPY --from=builder` copia solo el binario de la etapa anterior; el compilador y el código fuente quedan descartados.

**8. Construir la imagen multi-stage:**

```bash
docker build -f Dockerfile.multi -t lab04-app:multistage .
```

**9. Comparar los tamaños:**

```bash
docker image ls lab04-app
```

La imagen multi-stage debería pesar menos de 20 MB. La diferencia suele ser de 90–95%.

### Parte 4: verificar el contenido de la imagen final

**10. Verificar que el compilador de Go no está en la imagen final:**

```bash
docker run --rm lab04-app:multistage which go 2>&1 || echo "go no encontrado — correcto"
```

Si la salida es `go no encontrado`, el compilador no está en la imagen.

**11. Verificar que el binario funciona:**

```bash
docker run -d --name lab-multistage -p 8080:8080 lab04-app:multistage
sleep 1
curl http://localhost:8080
```

Resultado esperado: una línea con `Sesion 4 - Multi-stage build` y el nombre del contenedor.

**12. Ver el historial de capas de cada imagen:**

```bash
docker image history lab04-app:single
echo "---"
docker image history lab04-app:multistage
```

Observa que la imagen single-stage muestra capas de `golang:1.22-alpine`. La multi-stage muestra capas de `alpine:3.21` más el `COPY --from=builder`.

### Parte 5: construir solo hasta una etapa específica

En ocasiones necesitas depurar dentro del entorno de compilación. Puedes detener el build en una etapa concreta con `--target`.

**13. Construir la etapa builder para depuración:**

```bash
docker build -f Dockerfile.multi --target builder -t lab04-app:debug .
docker image ls lab04-app:debug
```

Esta imagen contiene el compilador. Úsala para explorar el entorno de compilación:

```bash
docker run --rm lab04-app:debug sh -c "which go && go version"
```

## Validación

- [ ] `docker image ls lab04-app` muestra dos imágenes: `single` y `multistage`.
- [ ] La imagen `multistage` pesa menos de 20 MB.
- [ ] La diferencia de tamaño entre `single` y `multistage` es mayor al 80%.
- [ ] `docker run --rm lab04-app:multistage which go` no encuentra el compilador.
- [ ] `curl http://localhost:8080` devuelve la respuesta del servidor.
- [ ] `docker image history lab04-app:multistage` no muestra capas de `golang`.

## Limpieza

```bash
docker rm -f lab-multistage 2>/dev/null || true
docker image rm lab04-app:single lab04-app:multistage lab04-app:debug 2>/dev/null || true
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| `cannot find package "net/http"` en el build | El archivo `go.mod` no está en el directorio de contexto | Verifica que `go.mod` y `main.go` están en el mismo directorio |
| La imagen `multistage` da el mismo tamaño que `single` | Usaste `Dockerfile.single` en ambos builds | Verifica el flag `-f Dockerfile.multi` en el segundo build |
| `curl` devuelve `Connection refused` | El contenedor no terminó de arrancar | Espera 2 segundos y reintenta, o verifica `docker logs lab-multistage` |
| `go build` falla con error de módulos | El módulo no tiene la ruta correcta | Verifica que `go.mod` contenga `module lab04/servidor` |
| `COPY --from=builder: not found` | El nombre de la etapa no coincide | El `AS builder` del primer `FROM` y el `--from=builder` del `COPY` deben ser idénticos |
