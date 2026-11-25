variable "aws_region" {
  description = "Región seleccionada de despliegue en AWS"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Prefijo de recursos del proyecto"
  type        = string
  default     = "devops-final"
}
