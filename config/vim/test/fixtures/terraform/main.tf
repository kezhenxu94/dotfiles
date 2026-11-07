variable "greeting" {
  type    = string
  default = "hello"
}

output "message" {
  value = var.greeting
}
