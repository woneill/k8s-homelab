resource "authentik_source_oauth" "github" {
  name                = "GitHub"
  slug                = "github"
  provider_type       = "github"
  authentication_flow = data.authentik_flow.default_source_authentication.id
  enrollment_flow     = authentik_flow.google_source_enrollment.uuid
  user_matching_mode  = "username_link"
  property_mappings   = [authentik_property_mapping_source_oauth.keeper_username.id]
  oidc_jwks_url       = "https://token.actions.githubusercontent.com/.well-known/jwks"

  consumer_key    = data.sops_file.secrets.data["github.client_id"]
  consumer_secret = data.sops_file.secrets.data["github.client_secret"]
}

resource "authentik_policy_binding" "github_allowlist" {
  target = authentik_source_oauth.github.uuid
  policy = authentik_policy_expression.email_allowlist.id
  order  = 0
}
