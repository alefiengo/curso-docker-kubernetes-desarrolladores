# Plan del Curso

## Resumen

Curso práctico de Docker y Kubernetes para desarrolladores. 20 horas distribuidas en 10 sesiones de 2 horas.

A lo largo del curso verás cómo una misma aplicación evoluciona desde ejecución local en contenedores hasta despliegue en Kubernetes con exposición, configuración, probes y escalado.

## Entorno

El entorno estándar es una terminal Linux. En Windows, el flujo recomendado es WSL 2 con Ubuntu 24.04 y Docker Desktop como motor de Docker. Los comandos del curso se ejecutan desde Ubuntu/WSL, no desde PowerShell ni CMD, salvo pasos explícitos de preparación.

La preparación de Docker está documentada en [Instalación del Entorno Docker](docs/instalacion-entorno-docker.md).

Kubernetes se prepara en su bloque correspondiente con una herramienta local separada como minikube o MicroK8s. No se usa el Kubernetes integrado de Docker Desktop.

## Al finalizar el curso podrás

- Construir imágenes Docker funcionales y optimizadas.
- Ejecutar, inspeccionar y depurar contenedores.
- Orquestar aplicaciones multi-servicio con Docker Compose.
- Aplicar escaneo básico de vulnerabilidades.
- Desplegar aplicaciones en Kubernetes con Pods, Deployments y Services.
- Gestionar configuración y secretos.
- Exponer servicios con NodePort o Ingress.
- Aplicar health checks y escalado horizontal básico.

## Estructura General

| Bloque | Sesiones | Horas | Enfoque |
|---|---:|---:|---|
| Docker fundamentos | 1–3 | 6h | Contenedores, imágenes, Dockerfile y registro |
| Docker aplicado | 4–7 | 8h | Multi-stage builds, Compose, microservicios y seguridad |
| Kubernetes | 8–10 | 6h | Pods, Deployments, Services, configuración, Ingress y escalado |

## Desafíos Opcionales

Cada sesión incluye un desafío opcional para profundizar fuera del horario de clase. No se entregan y no son requisito para avanzar a la siguiente sesión.

## Sesiones

### [Sesión 1: Fundamentos de Contenedores](sesiones/sesion-01-fundamentos-contenedores/README.md)

Contenedores vs máquinas virtuales, imágenes, registros y primeros comandos Docker. Práctica con `hello-world`, `nginx` y contenedores interactivos.

### [Sesión 2: Imágenes, Docker Hub y Ciclo de Vida](sesiones/sesion-02-imagenes-ciclo-vida/README.md)

Imágenes oficiales, tags, `docker pull`, `docker images`, `docker inspect`, variables de entorno y volúmenes introductorios.

### [Sesión 3: Dockerfiles y Construcción de Imágenes](sesiones/sesion-03-dockerfiles/README.md)

Anatomía de un `Dockerfile`, build context, `.dockerignore`, instrucciones principales y construcción de imágenes propias.

### [Sesión 4: Multi-stage Builds y Optimización](sesiones/sesion-04-multistage-optimizacion/README.md)

Capas, caché, multi-stage builds, imágenes base minimales, usuario no root y reducción de tamaño.

### [Sesión 5: Docker Compose, Redes y Volúmenes](sesiones/sesion-05-compose-redes-volumenes/README.md)

`compose.yaml`, services, networks, volumes, DNS interno y persistencia.

### [Sesión 6: Microservicios con Base de Datos, Caché y Gateway](sesiones/sesion-06-microservicios/README.md)

Conjunto multi-servicio con API, base de datos, caché y gateway. Depuración con logs y pruebas de conectividad.

### [Sesión 7: Seguridad, Escaneo y Preparación para Kubernetes](sesiones/sesion-07-seguridad/README.md)

Escaneo con Trivy, interpretación básica de resultados, refuerzo de seguridad y limpieza del bloque Docker.

### [Sesión 8: Kubernetes: Arquitectura, Pods y Deployments](sesiones/sesion-08-kubernetes-pods-deployments/README.md)

Cluster, control plane, worker nodes, `kubectl`, Pods, Deployments, ReplicaSets, escalado y autorrecuperación.

### [Sesión 9: Services, Configuración y Persistencia](sesiones/sesion-09-services-configuracion/README.md)

Services, labels, selectors, ConfigMaps, Secrets, volúmenes persistentes y StatefulSet como concepto.

### [Sesión 10: Ingress, Probes, HPA, Observabilidad y Cierre](sesiones/sesion-10-ingress-probes-hpa/README.md)

Ingress, liveness/readiness probes, Metrics Server, HPA, logs, métricas y cierre del bloque Kubernetes.
