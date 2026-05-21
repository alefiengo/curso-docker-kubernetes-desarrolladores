# Desafío Opcional: Sesión 1

Esta práctica es para reforzar y profundizar lo visto después de clase. No se entrega y no es requisito para la siguiente sesión.

## Objetivo

Explorar Docker con autonomía: elegir una imagen que te interese, ejecutarla con criterio, inspeccionar su comportamiento y documentar lo que descubres.

## Tiempo Estimado

30 a 45 minutos.

## Instrucciones

### 1. Elige una imagen oficial

Visita [hub.docker.com](https://hub.docker.com/) y elige una imagen oficial de una tecnología que uses o quieras explorar. Algunas sugerencias:

- `postgres` — base de datos relacional
- `redis` — almacenamiento en memoria
- `python` — intérprete interactivo
- `node` — entorno JavaScript
- `httpd` — servidor Apache

No uses `latest`. Elige un tag de versión específica o una variante `alpine`.

### 2. Lee la documentación de la imagen antes de ejecutarla

En la página de Docker Hub de la imagen que elegiste, identifica:

- ¿Qué variables de entorno acepta?
- ¿En qué puerto escucha por defecto?
- ¿Requiere alguna configuración obligatoria para arrancar?

### 3. Ejecuta el contenedor

Con lo que leíste, construye el comando `docker run` adecuado. El contenedor debe:

- Tener un nombre que empiece por `lab-`.
- Ejecutarse en segundo plano si el servicio lo permite.
- Tener al menos una variable de entorno configurada si la imagen lo requiere.

### 4. Verifica que funciona

Usa al menos tres de los siguientes comandos para confirmar que el servicio está operativo:

```bash
docker ps --filter "name=lab-"
docker logs <contenedor>
docker inspect <contenedor>
docker top <contenedor>
docker exec -it <contenedor> <comando>
```

### 5. Responde estas preguntas

Escribe las respuestas en un archivo o en tus notas personales:

- ¿Qué tag elegiste y por qué?
- ¿Qué variable de entorno configuraste y qué efecto tiene?
- ¿Cuál es el proceso principal del contenedor según `docker top`?
- ¿Qué información relevante encontraste en `docker inspect` que no te da `docker ps`?
- ¿Qué harías diferente si fuera un entorno de producción?

## Limpieza

```bash
docker rm -f $(docker ps -aq --filter "name=lab-") 2>/dev/null || true
```
