locals {
  repos = try(toset(jsondecode(var.repos)), toset(var.repos))

  repo_lifecycle_policies = flatten([
    for policy_key, policy_value in try(jsondecode(var.repo_lifecycle_policies), var.repo_lifecycle_policies) : {
      for repo in local.repos :
        replace("${repo}!${policy_key}", "/", "|") => merge(policy_value, { "repo" = repo }) if length(regexall(policy_value.repo_regexp, repo)) > 0
    }
  ])

  iam_bindings = flatten([
    for binding_key, binding_value in try(jsondecode(var.iam_bindings), var.iam_bindings) : {
      for repo in local.repos :
        replace("${repo}!${binding_key}", "/", "|") => merge(binding_value, { "repo" = repo }) if length(regexall(binding_value.repo_regexp, repo)) > 0
    }
  ])
}

resource "yandex_container_registry" "registry" {
  name = var.name
}

resource "yandex_container_repository" "repos" {
  for_each = local.repos
  name = "${yandex_container_registry.registry.id}/${each.key}"
}

resource "yandex_container_repository_lifecycle_policy" "policy" {
  for_each      = length(local.repo_lifecycle_policies) > 0 ? local.repo_lifecycle_policies[0] : {}
  name          = each.key
  status        = "active"
  repository_id = yandex_container_repository.repos[each.value.repo].id

  dynamic "rule" {
    for_each = each.value.rules
    content {
      description = lookup(rule.value, "description", null)
      expire_period = lookup(rule.value, "expire_period", null)
      tag_regexp = lookup(rule.value, "tag_regexp", null)
      untagged = lookup(rule.value, "untagged", null)
      retained_top = lookup(rule.value, "retained_top", null)
    }
  }
}

resource "yandex_container_repository_iam_binding" "binding" {
  for_each      = length(local.iam_bindings) > 0 ? local.iam_bindings[0] : {}
  repository_id = yandex_container_repository.repos[each.value.repo].id
  role          = each.value.role
  members       = each.value.members
}
