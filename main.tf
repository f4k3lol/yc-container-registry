locals {
  repos = toset(try(jsondecode(var.repos), var.repos))
}

resource "yandex_container_registry" "registry" {
  name = var.name
}

resource "yandex_container_repository" "repos" {
  for_each = local.repos
  name = "${yandex_container_registry.registry.id}/${each.key}"
}

resource "yandex_container_repository_lifecycle_policy" "policy" {
  for_each      = local.repos
  name          = "${each.key}-policy"
  status        = "active"
  repository_id = yandex_container_repository.repos[each.key].id

  dynamic "rule" {
    for_each = try(jsondecode(var.rules), var.rules)
    content {
      description = lookup(rule.value, "description", null)
      expire_period = lookup(rule.value, "expire_period", null)
      tag_regexp = lookup(rule.value, "tag_regexp", null)
      untagged = lookup(rule.value, "untagged", null)
      retained_top = lookup(rule.value, "retained_top", null)
    }
  }
}

