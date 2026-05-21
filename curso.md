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
| Docker fundamentos | 1–4 | 8h | Contenedores, imágenes, Docker Hub, Dockerfile y optimización |
| Docker aplicado | 5–7 | 6h | Compose, microservicios, seguridad e introducción a Kubernetes |
| Kubernetes | 8–10 | 6h | Pods, Deployments, Services, configuración, Ingress y escalado |

## Desafíos Opcionales

Cada sesión incluye un desafío opcional para profundizar fuera del horario de clase. No se entregan y no son requisito para avanzar a la siguiente sesión.

## Sesiones

### [Sesión 1: Fundamentos de Contenedores](sesiones/sesion-01-fundamentos-contenedores/README.md)

Contenedores vs máquinas virtuales, imágenes, registros y primeros comandos Docker. Práctica con `hello-world`, `nginx` y contenedores interactivos.

### [Sesión 2: Imágenes, Docker Hub y Ciclo de Vida](sesiones/sesion-02-imagenes-ciclo-vida/README.md)

Capas y estructura interna de las imágenes, inspección, Docker Hub, tags, variables de entorno, ciclo de vida completo del contenedor y persistencia básica con volúmenes.

### [Sesión 3: Dockerfiles y Publicación](sesiones/sesion-03-dockerfiles/README.md)

Anatomía de un `Dockerfile`, instrucciones principales, build context, `.dockerignore`, CMD vs ENTRYPOINT y publicación de imágenes propias en Docker Hub.

### [Sesión 4: Multi-stage Builds y Optimización](sesiones/sesion-04-multistage-optimizacion/README.md)

Capas, caché de build, multi-stage builds, imágenes base minimales y usuario no root.

### [Sesión 5: Docker Compose, Redes y Volúmenes](sesiones/sesion-05-compose-redes-volumenes/README.md)

`compose.yaml`, services, redes personalizadas, DNS interno entre servicios y volúmenes nombrados con persistencia.

### [Sesión 6: Microservicios y Seguridad](sesiones/sesion-06-microservicios-seguridad/README.md)

Stack multi-servicio con API, base de datos, caché y gateway. Escaneo de vulnerabilidades con Trivy y hardening básico de imágenes.

### [Sesión 7: Fundamentos de Kubernetes](sesiones/sesion-07-fundamentos-kubernetes/README.md)

Qué problema resuelve Kubernetes, arquitectura de alto nivel, componentes del cluster e instalación y validación del entorno local con minikube y kubectl.

### [Sesión 8: Pods y Deployments](sesiones/sesion-08-pods-deployments/README.md)

Pods como unidad mínima, manifiestos YAML, Deployments, ReplicaSets, escalado y autorrecuperación.

### [Sesión 9: Services, Configuración y Persistencia](sesiones/sesion-09-services-configuracion/README.md)

ClusterIP, NodePort, labels, selectors, ConfigMaps, Secrets y volúmenes persistentes.

### [Sesión 10: Ingress, Probes, HPA y Cierre](sesiones/sesion-10-ingress-probes-hpa/README.md)

Ingress controller, liveness y readiness probes, Metrics Server, HPA y cierre del bloque Kubernetes.
