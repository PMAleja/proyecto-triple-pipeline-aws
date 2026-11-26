# Proyecto Triple Pipeline DevOps en AWS

Infraestructura (Terraform) → Código y Versionado (Docker + ECR) → Despliegue y Monitoreo (ECS Fargate), automatizados con GitHub Actions en la Región seleccionada `us-east-2`.

## Estructura
- `.github/workflows/` – los pipelines ejecutados por GitHub Actions
  - `1-infraestructura.yml` – Lint → Plan → Aprobación manual → Apply
  - `2-codigo-ecr.yml` – Build → Pruebas → Docker Build → Push a ECR (tag SHA corto + `latest`)
  - `3-despliegue-ecs.yml` – Task Definition → QA → Aprobación manual → Deploy Prod → Monitoreo HTTP
  - `4-destruir-infra.yml` – limpieza (`terraform destroy`) para reducir costos al terminar la demo
- `pipelines/` – copia exacta de los archivos `.yml` para la entrega
- `terraform/` – VPC por defecto, Security Group (puertos 80 y 3000), Rol IAM `devops-final-ecs-exec-role`, repositorios ECR con `scan_on_push`, CloudWatch Logs, clúster ECS Fargate, Task Definitions y Servicios
- `aplicacion/backend` – API Express (`/api/health` y `/api/tareas`) + prueba automatizada (`npm test`)
- `aplicacion/frontend` – página web estática con Nginx

## Autenticación segura (GitHub OIDC)
- En lugar de llaves estáticas IAM (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`), los pipelines autentican contra AWS mediante **federación OIDC de GitHub Actions** (`role-to-assume`), obteniendo credenciales temporales por ejecución y con permisos de mínimo privilegio limitados al repositorio y a la Región `us-east-2`.
- El estado remoto de Terraform se guarda en S3 (`devops-final-tfstate-<PROJECT_ID>`) con acceso público bloqueado y versionado habilitado.

## Secretos y Variables configurados (Settings → Secrets and variables → Actions)
- **Secret** `AWS_ROLE_ARN`: ARN del rol IAM de OIDC (`devops-final-github-actions-role`)
- **Variable** `AWS_REGION`: `us-east-2` (se usa como Variable y no como Secret para que GitHub Actions no bloquee outputs entre jobs que incluyan la región en los ARNs de ECS)

## Entornos de aprobación (Settings → Environments)
- `produccion-infra` y `produccion-deploy`, ambos protegidos con *Required reviewers*.

## Orden de ejecución
1. **Pipeline 1** → aprobar en `produccion-infra` → se crean ECR, SG, Rol IAM, CloudWatch Logs, clúster y servicios ECS (`desired_count = 0`).
2. **Pipeline 2** → instala dependencias, ejecuta `npm test` y sube las imágenes etiquetadas (`SHA` + `latest`) a ECR.
3. **Pipeline 3** → se dispara automáticamente al terminar Pipeline 2, registra nuevas Task Definitions, valida en QA, espera aprobación en `produccion-deploy`, despliega en ECS Fargate y verifica HTTP 200 imprimiendo `FRONTEND URL` y `BACKEND API`.
4. **Limpieza** → ejecutar **Limpieza - Destruir Infraestructura** cuando finalices la presentación para apagar ECS Fargate y evitar consumo innecesario de créditos.

No se almacena ninguna clave ni token en el repositorio.
