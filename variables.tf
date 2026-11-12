variable "subscription_id" {
  description = "Azure Subscription ID where resources will be deployed."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus2"
}

variable "project_name" {
  description = "Project prefix used for resource naming."
  type        = string
  default     = "aks-metrics"
}

variable "environment" {
  description = "Deployment environment label."
  type        = string
  default     = "dev"
}
