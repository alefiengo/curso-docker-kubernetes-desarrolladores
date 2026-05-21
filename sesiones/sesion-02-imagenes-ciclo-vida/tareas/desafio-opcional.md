# Desafío Opcional: Sesión 2

No se entrega y no es requisito para avanzar a la sesión 3.

## El reto

Elige una imagen de Docker Hub que no hayas usado antes. No uses `nginx`, `postgres`, `redis` ni `hello-world`.

Opciones sugeridas: `redis:7-alpine`, `mysql:8.4`, `mongo:7`, `rabbitmq:3-alpine`, `httpd:alpine`.

## Preguntas que debes poder responder

Antes de ejecutar la imagen:

1. ¿Qué hace esta imagen? Lee la descripción en hub.docker.com.
2. ¿Qué variables de entorno requiere o acepta?
3. ¿En qué directorio almacena sus datos persistentes?
4. ¿Qué puerto expone?

Después de ejecutarla:

5. ¿Cuántas capas tiene? (`docker image history`)
6. ¿Qué comando ejecuta por defecto? (`docker image inspect --format '{{.Config.Cmd}}'`)
7. ¿Qué procesos corren dentro? (`docker top`)
8. ¿Qué pasa con los datos si eliminas el contenedor y lo vuelves a crear sin volumen?
9. ¿Qué pasa si lo vuelves a crear con un volumen nombrado?

## Lo que debes hacer

```bash
docker pull <imagen>:<tag>
docker image inspect <imagen>:<tag>
docker image history <imagen>:<tag>

docker run -d \
  --name lab-desafio \
  -e VARIABLE=valor \
  -v datos-desafio:/ruta/de/datos \
  -p <puerto-local>:<puerto-interno> \
  <imagen>:<tag>

docker logs lab-desafio
docker top lab-desafio

# Prueba la persistencia:
# 1. Conecta y crea datos
# 2. Elimina el contenedor
# 3. Recrea con el mismo volumen
# 4. Verifica que los datos persisten

docker rm -f lab-desafio
docker volume rm datos-desafio
```

## Criterio de éxito

Puedes describir en una oración qué hace la imagen, qué variables necesita y cómo los datos persisten con un volumen nombrado.
