variable "name" {
  type = string
}

variable "repos" {
  default = []
}

variable "iam_bindings" {
  default = {}
}

variable "repo_lifecycle_policies" {
  default = {}
}