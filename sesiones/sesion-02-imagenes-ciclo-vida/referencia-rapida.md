# Referencia Rápida: Sesión 2

## Imágenes

```bash
docker pull nginx:alpine
docker pull postgres:16-alpine
docker image ls
docker image ls nginx
docker image ls --filter reference="nginx:*"
docker image ls --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"
docker image inspect nginx:alpine
docker image inspect nginx:alpine --format '{{.Os}}/{{.Architecture}}'
docker image inspect nginx:alpine --format '{{.Config.Cmd}}'
docker image inspect nginx:alpine --format '{{range .Config.Env}}{{println .}}{{end}}'
docker image inspect nginx:alpine --format '{{len .RootFS.Layers}}'
docker image inspect nginx:alpine --format '{{index .RepoDigests 0}}'
docker image history nginx:alpine
docker image rm nginx:alpine
docker image prune
```

## Variables de Entorno

```bash
docker run -d --name contenedor -e VARIABLE=valor imagen:tag
docker run -d --name contenedor --env-file variables.env imagen:tag
docker inspect contenedor --format '{{range .Config.Env}}{{println .}}{{end}}'
```

## Ciclo de Vida

```bash
docker ps
docker ps -a
docker ps --filter "name=prefijo"
docker logs contenedor
docker logs -f contenedor
docker logs --tail 20 contenedor
docker top contenedor
docker stop contenedor
docker start contenedor
docker exec -it contenedor bash
docker exec contenedor comando
```

## Volúmenes

```bash
docker volume create nombre-volumen
docker volume ls
docker volume inspect nombre-volumen
docker volume rm nombre-volumen
docker volume prune
docker run -d --name contenedor -v nombre-volumen:/ruta/interna imagen:tag
docker run -d --name contenedor -v /ruta/local:/ruta/interna imagen:tag
```
