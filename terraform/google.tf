data "authentik_stage" "default_authentication_identification" {
  name = "default-authentication-identification"
}

data "authentik_stage" "default_source_enrollment_prompt" {
  name = "default-source-enrollment-prompt"
}

data "authentik_stage" "default_source_enrollment_write" {
  name = "default-source-enrollment-write"
}

data "authentik_stage" "default_source_enrollment_login" {
  name = "default-source-enrollment-login"
}

resource "authentik_stage_identification" "default_authentication_identification" {
  name                      = "default-authentication-identification"
  case_insensitive_matching = true
  enable_remember_me        = false
  pretend_user_exists       = true
  show_matched_user         = true
  show_source_labels        = false
  user_fields               = ["email", "username"]
  sources = [
    authentik_source_oauth.google.uuid,
    authentik_source_oauth.github.uuid,
  ]
}

data "authentik_flow" "default_source_authentication" {
  slug = "default-source-authentication"
}

resource "authentik_flow" "google_source_enrollment" {
  name        = "Google source enrollment"
  slug        = "google-source-enrollment"
  title       = "Google source enrollment"
  designation = "enrollment"
}

resource "authentik_flow_stage_binding" "google_source_enrollment_prompt" {
  target = authentik_flow.google_source_enrollment.uuid
  stage  = data.authentik_stage.default_source_enrollment_prompt.id
  order  = 10
}

resource "authentik_flow_stage_binding" "google_source_enrollment_write" {
  target = authentik_flow.google_source_enrollment.uuid
  stage  = data.authentik_stage.default_source_enrollment_write.id
  order  = 20
}

resource "authentik_flow_stage_binding" "google_source_enrollment_login" {
  target = authentik_flow.google_source_enrollment.uuid
  stage  = data.authentik_stage.default_source_enrollment_login.id
  order  = 30
}

resource "authentik_property_mapping_source_oauth" "keeper_username" {
  name = "oauth-source-keeper-username"

  expression = <<EOT
email = str(info.get("email", "")).lower().strip()
allowed_emails = yamldecode(data.sops_file.secrets.raw).allowed_emails
if email in allowed_emails:
    return {"username": yamldecode(data.sops_file.secrets.raw).keeper_username}

return {}
EOT
}

resource "authentik_source_oauth" "google" {
  name                = "Google"
  slug                = "google"
  provider_type       = "google"
  authentication_flow = data.authentik_flow.default_source_authentication.id
  enrollment_flow     = authentik_flow.google_source_enrollment.uuid
  user_matching_mode  = "username_link"
  property_mappings   = [authentik_property_mapping_source_oauth.keeper_username.id]
  authorization_url   = "https://accounts.google.com/o/oauth2/v2/auth"
  access_token_url    = "https://oauth2.googleapis.com/token"
  profile_url         = "https://openidconnect.googleapis.com/v1/userinfo"
  oidc_jwks_url       = "https://www.googleapis.com/oauth2/v3/certs"

  consumer_key    = data.sops_file.secrets.data["google.client_id"]
  consumer_secret = data.sops_file.secrets.data["google.client_secret"]
}

resource "authentik_policy_expression" "google_username_mapping" {
  name = "google-username-mapping"

  expression = <<EOT
prompt_data = request.context.get("prompt_data", {})
email = str(prompt_data.get("email", "")).lower().strip()
allowed_emails = yamldecode(data.sops_file.secrets.raw).allowed_emails

if email in allowed_emails:
    prompt_data["username"] = yamldecode(data.sops_file.secrets.raw).keeper_username
elif email:
    prompt_data["username"] = email

request.context["prompt_data"] = prompt_data
return False
EOT
}

resource "authentik_policy_expression" "google_if_username_missing" {
  name = "google-source-enrollment-if-username"

  expression = <<EOT
# Check if we've not been given a username by the external IdP
# and trigger the enrollment flow
return 'username' not in context.get('prompt_data', {})
EOT
}

resource "authentik_policy_binding" "google_username_mapping" {
  target = authentik_flow_stage_binding.google_source_enrollment_prompt.id
  policy = authentik_policy_expression.google_username_mapping.id
  order  = -100
}

resource "authentik_policy_binding" "google_if_username_missing" {
  target = authentik_flow_stage_binding.google_source_enrollment_prompt.id
  policy = authentik_policy_expression.google_if_username_missing.id
  order  = -90
}

resource "authentik_policy_binding" "google_allowlist" {
  target = authentik_source_oauth.google.uuid
  policy = authentik_policy_expression.email_allowlist.id
  order  = 0
}
