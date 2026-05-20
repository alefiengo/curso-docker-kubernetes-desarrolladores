# Proyecto Integrador

El proyecto integrador es el hilo conductor demostrativo del curso. El instructor lo usa en clase para mostrar cómo una misma aplicación evoluciona de un contenedor local a un despliegue Kubernetes observable y escalable.

No es el proyecto final entregable de los participantes.

## La Aplicación

API REST con CRUD de usuarios, base de datos relacional, caché y frontend web.

## Stack

| Componente | Tecnología |
|---|---|
| API | Spring Boot 3, Java 17 |
| Base de datos | PostgreSQL 16 |
| Caché | Redis 7 |
| Frontend | Angular (nginx como servidor) |

## Versiones

El proyecto tiene dos versiones que coinciden con los cierres de cada bloque:

| Versión | Cierre | Lo que incluye |
|---|---|---|
| `v1` | Bloque Docker (sesión 7) | Imagen optimizada con multi-stage build, usuario no root, `compose.yaml` con API + PostgreSQL + Redis, escaneo con Trivy. |
| `v2` | Bloque Kubernetes (sesión 10) | Todo lo de `v1` más manifiestos Kubernetes: `Deployment`, `Service`, `ConfigMap`, `Secret`, `Ingress`, probes y HPA. |

## Arquitectura

### Bloque Docker (v1)

```text
cliente
    |
  API :8080
    |
    +-- PostgreSQL :5432
    +-- Redis :6379
```

### Bloque Kubernetes (v2)

```text
cliente
    |
Ingress :80
    |
    +-- Frontend Pods
    +-- API Pods
          |
          +-- PostgreSQL (StatefulSet)
          +-- Redis
```
