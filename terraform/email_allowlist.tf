resource "authentik_policy_expression" "email_allowlist" {
  name = "email-allowlist"

  expression = <<EOT
ALLOWED_EMAILS = {
%{for entry in try(yamldecode(data.sops_file.secrets.raw).user_mappings, [])~}
    "${entry.email}",
%{endfor~}
}

if not request.user.email:
    return False

email = request.user.email.lower().strip()
return email in ALLOWED_EMAILS
EOT
}
