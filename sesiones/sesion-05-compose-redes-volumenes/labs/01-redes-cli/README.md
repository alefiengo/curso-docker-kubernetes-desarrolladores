# Lab 01: Redes con Docker CLI

## Objetivo

Crear redes Docker manualmente, conectar contenedores a ellas y verificar que el aislamiento y el DNS interno funcionan como se espera antes de gestionar redes con Compose.

## Requisitos

- Docker funcionando (`docker version` responde sin errores).
- Docker Compose v2 (`docker compose version` responde con v2).

## Paso a paso

### Parte 1: red por defecto y sus limitaciones

Cuando arrancas un contenedor sin especificar red, Docker lo conecta a la red `bridge` por defecto. En esa red los contenedores se comunican por IP, pero no por nombre.

**1. Arrancar dos contenedores en la red por defecto:**

```bash
docker run -d --name c1 alpine:3.21 sleep 300
docker run -d --name c2 alpine:3.21 sleep 300
```

**2. Obtener la IP de c2:**

```bash
docker inspect c2 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```

Anota la IP. Será algo como `172.17.0.3`.

**3. Desde c1, hacer ping a c2 por IP:**

```bash
IP_C2=$(docker inspect c2 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
docker exec c1 ping -c2 $IP_C2
```

Funciona porque comparten la red `bridge`.

**4. Intentar hacer ping a c2 por nombre:**

```bash
docker exec c1 ping -c2 c2 2>&1 || echo "Nombre no resuelto — red bridge por defecto no tiene DNS"
```

Falla. La red `bridge` por defecto no tiene resolución DNS por nombre. Eso cambia con las redes definidas por el usuario.

**5. Limpiar los contenedores:**

```bash
docker rm -f c1 c2
```

### Parte 2: red definida por el usuario

Las redes creadas con `docker network create` sí tienen DNS interno: los contenedores se resuelven por nombre.

**6. Crear una red personalizada:**

```bash
docker network create lab05-red-a
```

**7. Arrancar dos contenedores en esa red:**

```bash
docker run -d --name nodo1 --network lab05-red-a alpine:3.21 sleep 300
docker run -d --name nodo2 --network lab05-red-a alpine:3.21 sleep 300
```

**8. Verificar que el DNS interno resuelve por nombre:**

```bash
docker exec nodo1 ping -c2 nodo2
docker exec nodo2 ping -c2 nodo1
```

Ambos se resuelven por nombre. El DNS interno de Docker asigna el nombre del contenedor como hostname dentro de la red.

**9. Inspeccionar la red:**

```bash
docker network inspect lab05-red-a
```

En la sección `Containers` aparecen `nodo1` y `nodo2` con sus IPs asignadas.

### Parte 3: aislamiento entre redes

**10. Crear una segunda red:**

```bash
docker network create lab05-red-b
```

**11. Arrancar un tercer contenedor en la red b:**

```bash
docker run -d --name nodo3 --network lab05-red-b alpine:3.21 sleep 300
```

**12. Verificar que nodo1 no puede alcanzar nodo3:**

```bash
docker exec nodo1 ping -c2 nodo3 2>&1 || echo "No alcanzable — redes distintas"
```

`nodo1` está en `lab05-red-a` y `nodo3` en `lab05-red-b`. No comparten red, por lo que no se comunican.

### Parte 4: docker network connect y disconnect

`docker network connect` conecta un contenedor en ejecución a una red adicional sin detenerlo.

**13. Conectar nodo1 a la red b:**

```bash
docker network connect lab05-red-b nodo1
```

**14. Verificar que nodo1 ahora alcanza nodo3:**

```bash
docker exec nodo1 ping -c2 nodo3
```

Funciona. `nodo1` está conectado a dos redes simultáneamente: `lab05-red-a` y `lab05-red-b`.

**15. Verificar las redes de nodo1:**

```bash
docker inspect nodo1 --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}'
```

Aparecen ambas redes.

**16. Desconectar nodo1 de la red b:**

```bash
docker network disconnect lab05-red-b nodo1
```

**17. Verificar que el aislamiento se restauró:**

```bash
docker exec nodo1 ping -c2 nodo3 2>&1 || echo "Aislamiento restaurado"
```

`nodo1` ya no alcanza `nodo3`.

### Parte 5: listar y eliminar redes

**18. Ver todas las redes del sistema:**

```bash
docker network ls
```

Verás las redes del sistema (`bridge`, `host`, `none`) y las dos redes del lab.

**19. Ver solo las redes del lab:**

```bash
docker network ls --filter name=lab05
```

**20. Eliminar un contenedor de una red antes de eliminar la red:**

No puedes eliminar una red mientras haya contenedores conectados a ella. Primero detén o elimina los contenedores:

```bash
docker rm -f nodo1 nodo2 nodo3
docker network rm lab05-red-a lab05-red-b
```

**21. Verificar que las redes fueron eliminadas:**

```bash
docker network ls --filter name=lab05
```

No aparece ninguna.

## Validación

- [ ] `docker exec nodo1 ping -c2 nodo2` resuelve el nombre y recibe respuesta (Parte 2).
- [ ] `docker exec nodo1 ping -c2 c2` falla en la red `bridge` por defecto (Parte 1).
- [ ] `docker exec nodo1 ping -c2 nodo3` falla antes de `docker network connect` (Parte 3).
- [ ] `docker exec nodo1 ping -c2 nodo3` funciona después de `docker network connect lab05-red-b nodo1` (Parte 4).
- [ ] `docker exec nodo1 ping -c2 nodo3` falla de nuevo después de `docker network disconnect` (Parte 4).
- [ ] `docker network ls --filter name=lab05` no muestra redes tras la limpieza (Parte 5).

## Limpieza

```bash
docker rm -f nodo1 nodo2 nodo3 c1 c2 2>/dev/null || true
docker network rm lab05-red-a lab05-red-b 2>/dev/null || true
```

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| `ping: bad address 'nodo2'` en la red `bridge` por defecto | La red por defecto no tiene DNS por nombre | Es el comportamiento esperado en la Parte 1; en la Parte 2 el mismo ping funciona porque se usa una red definida por el usuario |
| `Error response from daemon: network lab05-red-a id ... has active endpoints` al eliminar la red | Hay contenedores aún conectados a esa red | Elimina los contenedores primero con `docker rm -f nodo1 nodo2` |
| `docker exec nodo1 ping` devuelve `ping: command not found` | La imagen base no incluye `ping` | `alpine:3.21` lo incluye por defecto; si usas otra imagen, verifica con `docker run --rm alpine:3.21 which ping` |
| `docker network connect` falla con `endpoint with name nodo1 already exists` | El contenedor ya está conectado a esa red | No es necesario reconectarlo; verifica con `docker inspect nodo1` |
