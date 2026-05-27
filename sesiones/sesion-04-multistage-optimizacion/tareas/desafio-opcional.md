# Desafío Opcional: Sesión 4 — Multi-stage Builds y Optimización

Esta práctica es para reforzar lo visto después de clase. No se entrega y no es requisito para la siguiente sesión.

## Objetivo

Tomar la imagen que publicaste en el lab 04 de la sesión 3 y aplicar todas las técnicas de optimización de esta sesión. El resultado debe ser una imagen notablemente más pequeña, con usuario no root, y publicada en Docker Hub como versión `2.0`.

## Criterios mínimos

1. La imagen usa multi-stage build: la etapa de compilación o instalación de dependencias está separada de la imagen final.
2. La imagen base de la etapa final es `alpine`, `slim`, `distroless` o `scratch` según la tecnología.
3. El proceso corre con un usuario sin privilegios (UID mayor que 0).
4. El `Dockerfile` tiene el orden de instrucciones óptimo para la caché.
5. La imagen lleva el tag `tu-usuario/nombre-imagen:2.0` y está publicada en Docker Hub.
6. El tamaño de la versión `2.0` es menor que el de la versión `1.0`.
7. El contenedor arranca y responde correctamente con `docker run`.
8. El `Dockerfile` tiene un `.dockerignore` con al menos tres patrones relevantes.

## Forma de verificar

```bash
# Descargar la imagen desde Docker Hub (sin el código fuente local)
docker pull tu-usuario/nombre-imagen:2.0
docker run --rm tu-usuario/nombre-imagen:2.0

# Verificar el usuario
docker run --rm tu-usuario/nombre-imagen:2.0 whoami
docker run --rm tu-usuario/nombre-imagen:2.0 id

# Comparar tamaños
docker image ls tu-usuario/nombre-imagen
```

## Opciones de aplicación

Si la imagen que publicaste en la sesión 3 no es fácilmente optimizable o prefieres empezar con una nueva, puedes usar una de estas opciones:

### Opción A: API Python con Flask

```python
# app.py
from flask import Flask
app = Flask(__name__)

@app.route("/")
def index():
    return "Sesion 4 - Optimizado con Flask\n"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

Imagen base recomendada para la etapa final: `python:3.12-slim`.

### Opción B: Servidor Go estático

Usa el código del lab 01 de esta sesión. La imagen final puede ser `scratch` o `alpine:3.21`, ya que el binario Go compilado con `CGO_ENABLED=0` es totalmente estático.

Imagen base recomendada para la etapa final: `scratch` o `alpine:3.21`.

### Opción C: Aplicación Node.js con Express

```javascript
// app.js
const express = require('express');
const app = express();
app.get('/', (req, res) => res.send('Sesion 4 - Optimizado con Express\n'));
app.listen(3000);
```

Imagen base recomendada para la etapa final: `node:22-alpine`.

## Puntos adicionales para profundizar

Si completaste los criterios mínimos y quieres explorar más:

- Prueba `distroless/static-debian12` de Google para un binario Go y observa que no hay shell.
- Usa `docker scan` o `trivy image` para comparar el número de vulnerabilidades entre la versión `1.0` y la `2.0`.
- Agrega un `HEALTHCHECK` a la imagen para que Docker pueda sondear el estado del servicio.
- Usa `ARG` para parametrizar la versión de la imagen base y el puerto de la aplicación.
