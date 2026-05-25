# Referencia Rápida: Sesión 3 — Dockerfiles y Publicación

## Instrucciones del Dockerfile

```dockerfile
FROM imagen:tag                          # Imagen base (siempre la primera instrucción)
FROM imagen:tag AS nombre-etapa          # Imagen base con alias de etapa

WORKDIR /ruta                            # Directorio de trabajo (lo crea si no existe)
COPY origen destino                      # Copia desde el build context a la imagen
ADD origen.tar.gz /destino/              # Copia y desempaqueta (preferir COPY salvo necesidad)

RUN comando                              # Ejecuta durante el build (genera capa)
RUN apt-get update && \
    apt-get install -y paquete && \
    rm -rf /var/lib/apt/lists/*          # Combinar en un solo RUN para minimizar capas

ENV NOMBRE=valor                         # Variable de entorno (disponible en contenedor)
ARG NOMBRE=valor_por_defecto             # Argumento de build (solo durante el build)

EXPOSE 80                                # Documenta el puerto (no lo publica)
LABEL clave="valor"                      # Metadatos de la imagen
USER usuario                             # Cambia el usuario para instrucciones siguientes

CMD ["ejecutable", "arg1"]               # Comando por defecto (reemplazable en docker run)
ENTRYPOINT ["ejecutable"]                # Ejecutable fijo (argumentos en docker run se le pasan)
HEALTHCHECK CMD curl -f http://localhost/ || exit 1   # Verificación de salud
```

## Construir imágenes

```bash
# Build básico desde el directorio actual
docker build -t nombre:tag .

# Build sin usar caché
docker build --no-cache -t nombre:tag .

# Build con un Dockerfile de nombre alternativo
docker build -f Dockerfile.prod -t nombre:tag .

# Build con argumentos de build
docker build --build-arg VERSION=2.0 -t nombre:tag .

# Build con salida detallada (ver tamaño del contexto)
docker build --progress=plain -t nombre:tag .
```

## Inspeccionar imágenes

```bash
docker image ls                          # Listar imágenes locales
docker image ls nombre                   # Filtrar por nombre
docker image history nombre:tag          # Ver capas y tamaño de cada instrucción
docker image inspect nombre:tag          # Metadatos completos en JSON
docker image inspect nombre:tag --format '{{.Config.Cmd}}'
docker image inspect nombre:tag --format '{{.Config.Entrypoint}}'
docker image rm nombre:tag               # Eliminar imagen
docker image prune                       # Eliminar imágenes sin tag
docker image prune -a                    # Eliminar imágenes sin contenedor asociado
```

## Docker Hub

```bash
docker login                             # Iniciar sesión (pide usuario y contraseña)
docker logout                            # Cerrar sesión

docker tag imagen:tag usuario/imagen:tag # Etiquetar para el registro
docker push usuario/imagen:tag           # Publicar imagen
docker push usuario/imagen --all-tags    # Publicar todos los tags

docker pull usuario/imagen:tag           # Descargar imagen
docker search usuario/imagen             # Buscar en Docker Hub
```

## .dockerignore — exclusiones típicas

```
.git
.env
.env.*
node_modules
__pycache__
*.pyc
*.log
.DS_Store
*.swp
```

## CMD vs ENTRYPOINT: resumen rápido

| Escenario | `CMD` | `ENTRYPOINT` |
|---|---|---|
| `docker run imagen` | Ejecuta CMD | Ejecuta ENTRYPOINT |
| `docker run imagen arg` | Reemplaza CMD con `arg` | Pasa `arg` a ENTRYPOINT |
| Para reemplazar el ejecutable | Automático con cualquier arg | Requiere `--entrypoint` |
| Uso típico | Comando por defecto cambiable | Ejecutable fijo de propósito único |

## Patrón ENTRYPOINT + CMD

```dockerfile
ENTRYPOINT ["ejecutable"]    # Fijo
CMD ["argumento-por-defecto"] # Sobrescribible con docker run imagen otro-argumento
```

## Limpieza general

```bash
docker system df                         # Ver uso de disco
docker system prune                      # Eliminar contenedores, redes e imágenes sin uso
docker system prune -a                   # Incluir también imágenes sin contenedor
docker builder prune                     # Limpiar caché de build
```
