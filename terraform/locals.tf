locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }
}
