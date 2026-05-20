# Referencia Rápida: Sesión 1

## Verificar Docker

```bash
docker --version
docker info
```

## Ejecutar Contenedores

```bash
docker run hello-world
docker run --rm hello-world
docker run --name lab-hello hello-world
docker run -d --name lab-web -p 8080:80 nginx:alpine
docker run -it --name lab-shell ubuntu:24.04 bash
```

## Flags Comunes

| Flag | Uso |
|---|---|
| `-d` | Ejecuta el contenedor en segundo plano |
| `-it` | Abre sesión interactiva con terminal |
| `--name` | Asigna nombre al contenedor |
| `-p host:contenedor` | Publica un puerto del contenedor en el host |
| `--rm` | Elimina el contenedor automáticamente al terminar |

## Listar Recursos

```bash
docker ps
docker ps -a
docker images
docker container ls
docker container ls -a
docker image ls
```

## Logs e Inspección

```bash
docker logs lab-hello
docker logs --tail 10 lab-web
docker logs -f lab-web
docker inspect lab-web
docker top lab-web
bash scripts/estado.sh
```

## Ciclo de Vida

```bash
docker stop lab-web
docker start lab-web
docker restart lab-web
docker rm lab-hello
docker rm -f lab-web
```

## Probar Servicio Web

```bash
curl http://localhost:8080
```

Navegador:

```text
http://localhost:8080
```

## Limpieza de la Sesión

```bash
docker rm lab-hello
docker rm -f lab-web lab-shell
docker ps -a --filter "name=lab-"
```

## Errores Frecuentes

Puerto ocupado:

```bash
docker run -d --name lab-web -p 8081:80 nginx:alpine
```

Nombre ocupado:

```bash
docker rm -f lab-web
```

Docker no responde:

```bash
docker info
```

Descarga de imagen:

```bash
docker pull nginx:alpine
```
