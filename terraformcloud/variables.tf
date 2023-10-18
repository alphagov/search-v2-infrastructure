variable "environments" {
  type        = set(string)
  description = "Names of environments to create resource sets for"
  default     = ["dev", "integration", "staging", "production"]
}
