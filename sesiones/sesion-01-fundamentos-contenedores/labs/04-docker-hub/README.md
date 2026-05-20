# Lab 04: Docker Hub y tags

## Objetivo

Explorar Docker Hub, entender el sistema de tags, comparar variantes de una misma imagen y aplicar el criterio correcto para elegir una imagen base.

## Requisitos

- Docker en ejecución.
- Navegador web disponible.
- Conexión a internet.

## Paso a paso

### 1. Explorar Docker Hub en el navegador

Abre [hub.docker.com](https://hub.docker.com/) y busca `nginx`.

En la página de la imagen oficial (`hub.docker.com/_/nginx`) observa:

- La sección **Tags** lista todas las versiones disponibles.
- La sección **Overview** documenta cómo usar la imagen y qué variables acepta.
- El indicador **Docker Official Image** confirma que es mantenida por el proyecto oficial.

### 2. Buscar imágenes desde la terminal

```bash
docker search nginx --filter "is-official=true"
```

La columna `OFFICIAL` con valor `[OK]` indica imagen oficial. Las imágenes oficiales son mantenidas directamente por Docker o por el proyecto propietario de la tecnología.

### 3. Descargar imágenes con tags específicos

```bash
docker pull nginx:1.30-alpine
docker pull nginx:alpine
```

**Por qué importa el tag:**

| Tag | Comportamiento |
|---|---|
| `nginx` o `nginx:latest` | Apunta a la versión más reciente en el momento del `pull`. Puede cambiar. |
| `nginx:1.30` | Versión mayor y menor fija. Recibe actualizaciones de parche. |
| `nginx:1.30.1` | Versión exacta fija. No cambia nunca. Recomendada en entornos productivos. |
| `nginx:alpine` | Variante basada en Alpine Linux. Imagen base mínima, menor superficie de ataque. |
| `nginx:1.30-alpine` | Versión y variante fijas. Mejor opción cuando se busca reproducibilidad y tamaño reducido. |

### 4. Comparar tamaños

```bash
docker images nginx
```

La variante `alpine` ocupa significativamente menos espacio que la variante Debian por defecto. Menos capas, menos paquetes, menor superficie de ataque.

### 5. Ejecutar dos versiones en paralelo

```bash
docker run -d --name lab-hub-latest -p 8083:80 nginx:latest
docker run -d --name lab-hub-alpine -p 8084:80 nginx:1.30-alpine
docker ps --filter "name=lab-hub-"
```

Probar ambos:

```bash
curl http://localhost:8083
curl http://localhost:8084
```

El resultado funcional es idéntico. La diferencia está en el tamaño de la imagen y la base del sistema operativo.

### 6. Explorar imágenes de otras tecnologías

Busca en Docker Hub las imágenes oficiales de al menos dos de las siguientes tecnologías y anota el tag más adecuado para un entorno de desarrollo:

- `postgres`
- `redis`
- `python`
- `node`

Descarga una de ellas y verifica su tamaño:

```bash
docker pull <imagen>:<tag>
docker images <imagen>
```

## Validación

```bash
docker images nginx
docker ps --filter "name=lab-hub-"
```

La práctica está completa si:

- [ ] Tienes al menos dos variantes de `nginx` descargadas localmente.
- [ ] Ambos contenedores responden en sus puertos.
- [ ] Puedes explicar la diferencia entre usar `latest` y un tag de versión específica.
- [ ] Puedes explicar cuándo conviene usar la variante `alpine`.

## Limpieza

```bash
docker rm -f lab-hub-latest lab-hub-alpine
docker image prune -f
```

Para eliminar también las imágenes descargadas en este lab:

```bash
docker rmi nginx:latest nginx:alpine nginx:1.30-alpine
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| `manifest for <imagen>:<tag> not found` | El tag no existe en Docker Hub | Verificar los tags disponibles en la pestaña Tags de Docker Hub |
| `Bind for 0.0.0.0:8083 failed: port is already allocated` | El puerto ya está en uso | Cambiar el puerto del anfitrión en el comando `-p` |
| Descarga lenta o fallida | Problema de red o proxy corporativo | Verificar conectividad con `docker pull hello-world` |
