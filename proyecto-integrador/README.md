# Proyecto Integrador

El proyecto integrador es el hilo conductor del curso. La misma aplicación evoluciona de un contenedor local a un despliegue Kubernetes observable y escalable. No es el proyecto final entregable de los estudiantes.

## La Aplicación

API REST con CRUD de usuarios, base de datos relacional, caché y frontend web.

## Stack

| Componente | Tecnología |
|---|---|
| API | Spring Boot 3, Java 21 |
| Base de datos | PostgreSQL 16 |
| Caché | Redis 7 |
| Frontend | Angular 19, nginx |
| API Gateway (bloque Docker) | Kong 3 |

## Versiones

El proyecto tiene dos versiones que coinciden con los cierres de cada bloque:

| Versión | Cierre | Lo que incluye |
|---|---|---|
| `v1` | Bloque Docker (sesión 7) | Multi-stage build, usuario no root, `compose.yaml` con API + PostgreSQL + Redis + Kong, escaneo con Trivy. |
| `v2` | Bloque Kubernetes (sesión 10) | Todo lo de `v1` más manifiestos Kubernetes: `Deployment`, `Service`, `ConfigMap`, `Secret`, `Ingress`, probes y HPA. |

## Arquitectura

### Bloque Docker (v1)

```text
navegador
    |
Angular :4200 (nginx BFF)
    |
Kong :8000
    |
  API :8080
    |
    +-- PostgreSQL :5432
    +-- Redis :6379
```

### Bloque Kubernetes (v2)

```text
navegador
    |
Ingress :80
    |
    +-- Frontend Pods (nginx BFF)
    +-- API Pods
          |
          +-- PostgreSQL (StatefulSet)
          +-- Redis
```
