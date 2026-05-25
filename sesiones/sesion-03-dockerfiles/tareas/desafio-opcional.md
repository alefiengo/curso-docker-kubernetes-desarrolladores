# Desafío Opcional: Sesión 3

Esta práctica es para reforzar lo aprendido fuera del horario de clase. No se entrega y no es requisito para la sesión siguiente.

## El reto

Dockeriza una aplicación real en un lenguaje que uses habitualmente, publícala en Docker Hub y verifica que funciona sin el código fuente.

## Requisitos mínimos

El `Dockerfile` debe cumplir todos estos criterios:

1. **Imagen base con tag fijo**: nada de `latest`; usar una versión concreta (`python:3.12-slim`, `node:22-alpine`, `golang:1.23-alpine`, etc.).
2. **`WORKDIR` explícito**: no copiar archivos a la raíz del sistema de archivos.
3. **`.dockerignore` presente**: excluir al menos `.git`, `.env` y los directorios de dependencias locales.
4. **`RUN` combinado**: si instalas paquetes del sistema, hacerlo en un solo `RUN` con `&&` para no generar capas intermedias innecesarias.
5. **`LABEL`**: incluir al menos un metadato (`maintainer`, `version` o `description`).
6. **`EXPOSE`**: documentar el puerto de la aplicación.
7. **Forma exec en `CMD` o `ENTRYPOINT`**: nunca la forma shell.
8. **Publicada en Docker Hub**: la imagen debe poderse descargar con `docker pull tu-usuario/repositorio:tag`.

## Opciones de aplicación

Si no tienes una aplicación propia a mano, puedes usar alguna de estas ideas:

### Opción A: Servidor HTTP estático en Python

```python
# server.py
from http.server import HTTPServer, SimpleHTTPRequestHandler
import os

PORT = int(os.environ.get("PORT", 8080))
server = HTTPServer(("", PORT), SimpleHTTPRequestHandler)
print(f"Escuchando en :{PORT}")
server.serve_forever()
```

Sirve los archivos del directorio actual en el puerto `PORT`.

### Opción B: API mínima con Node.js

```javascript
// server.js
const http = require('http');
const PORT = process.env.PORT || 3000;
http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'application/json'});
  res.end(JSON.stringify({ ok: true, ruta: req.url }));
}).listen(PORT, () => console.log(`Escuchando en :${PORT}`));
```

### Opción C: Binario Go compilado dentro del Dockerfile

Compila y empaqueta un servidor Go usando solo instrucciones `RUN`:

```go
// main.go
package main

import (
    "fmt"
    "net/http"
    "os"
)

func main() {
    port := os.Getenv("PORT")
    if port == "" { port = "8080" }
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, `{"ok":true}`)
    })
    fmt.Println("Escuchando en :" + port)
    http.ListenAndServe(":"+port, nil)
}
```

## Criterios de éxito

- [ ] `docker build` completa sin errores.
- [ ] `docker run` arranca el contenedor y la aplicación responde.
- [ ] `docker image history` muestra las capas del build.
- [ ] `docker push` completa sin errores.
- [ ] Al eliminar la imagen local y ejecutar `docker pull + docker run`, la aplicación sigue funcionando.
- [ ] Ningún secreto, credencial ni archivo `.env` está incluido en la imagen (`docker run --rm imagen env` no muestra contraseñas reales).

## Pista para ir más allá

Si quieres practicar antes de la sesión 4, intenta reducir el tamaño de tu imagen usando una imagen base `slim` o `alpine` en lugar de la imagen estándar. Compara los tamaños con `docker image ls` y el detalle de capas con `docker image history`.
