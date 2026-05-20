# Problemas Frecuentes

Si algo falla durante un laboratorio, sigue este orden antes de pedir soporte: leer el mensaje de error completo, ejecutar el comando de diagnóstico correspondiente y revisar la sección de limpieza del lab para asegurarte de que no quedan recursos de una ejecución anterior.

## Docker

| Error | Causa | Solución |
|---|---|---|
| `Cannot connect to the Docker daemon` | El servicio Docker no está corriendo o el socket no tiene permisos. | Windows/Mac: reinicia Docker Desktop. Linux: `sudo systemctl restart docker`. Verifica tu usuario con `groups`. |
| `Bind for 0.0.0.0:<puerto> failed: port is already allocated` | Otro contenedor o proceso local usa el puerto. | `docker ps` para identificar el contenedor. Detén el proceso o usa un puerto distinto: `-p 9000:80`. |
| `No space left on device` | Acumulación de imágenes y volúmenes huérfanos. | `docker system prune -a --volumes`. Revisa uso con `docker system df`. |
| `The container name "..." is already in use` | Quedó un contenedor con ese nombre de una ejecución anterior. | `docker rm -f <nombre>` y vuelve a ejecutar el comando del lab. |
| `Unable to find image '...' locally` seguido de error de descarga | Sin conectividad al registro o proxy corporativo bloqueando. | `docker pull <imagen>` para ver el error completo. Revisa conectividad y configuración de proxy en Docker Desktop. |

## Kubernetes

| Error | Causa | Solución |
|---|---|---|
| Pod en `ImagePullBackOff` | Nombre de imagen o tag incorrecto, o falta de credenciales del registro. | `kubectl describe pod <nombre>` para ver el mensaje exacto. Verifica el nombre y tag de la imagen en el manifiesto. |
| Pod en `CrashLoopBackOff` | La aplicación falla al iniciar (variable de entorno faltante, error de configuración). | `kubectl logs <nombre> --previous` para ver la salida del intento anterior. |
| `Service` no responde | El selector del Service no coincide con los labels del Pod, o el puerto es incorrecto. | `kubectl get endpoints <nombre-service>`. Si está vacío, los labels no coinciden. |
| `kubectl apply` rechaza el manifiesto | Error de sintaxis YAML o campo no válido para la versión de API. | Leer el mensaje de error completo. Verificar indentación y que el `apiVersion` corresponde a la API actual. |
| Pod en `Pending` indefinidamente | Sin nodos con recursos suficientes o PVC sin proveedor de almacenamiento. | `kubectl describe pod <nombre>` sección Events. En minikube verificar que el cluster esté corriendo. |

## Diagnóstico general

```bash
# Docker: estado del daemon y recursos
docker info
docker system df

# Docker: inspeccionar un contenedor detenido
docker inspect <nombre>
docker logs <nombre>

# Kubernetes: ver el estado real de un objeto
kubectl describe pod <nombre>
kubectl describe deployment <nombre>
kubectl get events --sort-by='.lastTimestamp'
```
