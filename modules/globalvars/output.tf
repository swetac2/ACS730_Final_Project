# Default tags
output "default_tags" {
  value = {
    "App"   = "Two-Tier Application"
    "Project" = "Final ACS Project"
  }
}

# Prefix to identify resources
output "prefix" {
  value     = "Group123"
}