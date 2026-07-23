locals {
  grimmory_base_url = trimsuffix(data.sops_file.secrets.data["grimmory_base_url"], "/")
}

resource "authentik_user" "grimmory_keeper" {
  username = "woneill"
  email    = "woneill@woneill.com"
}

resource "authentik_group" "grimmory" {
  name  = "grimmory-users"
  users = [tonumber(authentik_user.grimmory_keeper.id)]
}

resource "authentik_group" "admins" {
  name         = "authentik-admins"
  is_superuser = true
  users        = [tonumber(authentik_user.grimmory_keeper.id)]
}

data "authentik_flow" "default_provider_authorization_implicit_consent" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default_provider_invalidation_flow" {
  slug = "default-provider-invalidation-flow"
}

data "authentik_certificate_key_pair" "authentik_self_signed" {
  name = "authentik Self-signed Certificate"
}

data "authentik_property_mapping_provider_scope" "openid" {
  managed = "goauthentik.io/providers/oauth2/scope-openid"
}

data "authentik_property_mapping_provider_scope" "profile" {
  managed = "goauthentik.io/providers/oauth2/scope-profile"
}

data "authentik_property_mapping_provider_scope" "email" {
  managed = "goauthentik.io/providers/oauth2/scope-email"
}

resource "authentik_property_mapping_provider_scope" "groups" {
  name       = "grimmory-oauth-groups"
  scope_name = "groups"
  expression = <<-EOT
    return {"groups": [group.name for group in request.user.groups.all()]}
  EOT
}

data "authentik_property_mapping_provider_scope" "offline_access" {
  managed = "goauthentik.io/providers/oauth2/scope-offline_access"
}

resource "authentik_provider_oauth2" "grimmory" {
  name          = "Grimmory OAuth2"
  client_id     = "grimmory"
  client_type   = "public"
  grant_types   = ["authorization_code", "refresh_token"]
  logout_method = "backchannel"
  logout_uri    = "${local.grimmory_base_url}/api/v1/auth/oidc/backchannel-logout"

  authorization_flow = data.authentik_flow.default_provider_authorization_implicit_consent.id
  invalidation_flow  = data.authentik_flow.default_provider_invalidation_flow.id
  signing_key        = data.authentik_certificate_key_pair.authentik_self_signed.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "${local.grimmory_base_url}/oauth2-callback"
    },
    {
      matching_mode     = "regex"
      redirect_uri_type = "authorization"
      url               = "${local.grimmory_base_url}/*"
    },
    {
      matching_mode     = "strict"
      redirect_uri_type = "logout"
      url               = "${local.grimmory_base_url}/login"
    }
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.profile.id,
    data.authentik_property_mapping_provider_scope.email.id,
    authentik_property_mapping_provider_scope.groups.id,
    data.authentik_property_mapping_provider_scope.offline_access.id,
  ]
}

resource "authentik_application" "grimmory" {
  name               = "Grimmory"
  slug               = "grimmory"
  group              = authentik_group.grimmory.id
  policy_engine_mode = "all"
  protocol_provider  = authentik_provider_oauth2.grimmory.id
}

resource "authentik_policy_binding" "grimmory_group_access" {
  target = authentik_application.grimmory.uuid
  group  = authentik_group.grimmory.id
  order  = 0
}
