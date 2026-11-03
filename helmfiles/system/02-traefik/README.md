# Traefik dashboard

The dashboard is available at `https://traefik-k8s.monkeyfaith.com/dashboard/`
(the trailing slash is required), with these protections:

- Only the HTTPS `websecure` entrypoint routes to the dashboard/API.
- `dashboard-lan-only` allows source addresses in `192.168.1.0/24`.
- `dashboard-basic-auth` requires a bcrypt-backed BasicAuth credential and removes
  the Authorization header before forwarding the request.
- cert-manager issues `traefik-dashboard-tls` using the existing
  `letsencrypt-production` DNS-01 ClusterIssuer.
- The insecure API listener is disabled.

The middleware and Certificate resources are in SOPS-encrypted `secrets.yaml`,
alongside the hostname and entrypoint override. Keep `extraObjects` there: Helm
replaces lists rather than merging them across values files.

## Set credentials before applying

From the repository root, run:

```sh
python3 helmfiles/system/02-traefik/set-dashboard-password.py
```

This requires `htpasswd`, `sops`, and access to the existing SOPS age key. It
prompts for a username and password locally, then adds or replaces the
`traefik-dashboard-auth` Secret in encrypted Helm values. Neither the password
nor the hash is passed as a command-line argument or written to a plaintext file.
Running it again replaces the credential (one user is managed by this helper).

Without the referenced Secret, Traefik cannot configure the BasicAuth middleware;
the dashboard should remain inaccessible, not fall back to unauthenticated access.
Do not remove the middleware reference to work around a missing Secret.

Apply the release with your normal Helmfile workflow after setting credentials.
The ClusterIssuer must already exist. Initial certificate issuance may take time;
do not bypass TLS verification if the certificate is not yet ready.

## Network requirements

`service.spec.externalTrafficPolicy: Local` preserves the client source IP for
LoadBalancer traffic. This setting affects **all traffic through the shared
Traefik Service**, not only the dashboard. With MetalLB, traffic must land on a
node with a ready Traefik endpoint; check reachability after the rollout.

The allowlist intentionally uses the connection source IP, not client-supplied
`X-Forwarded-For`. Access through a proxy, VPN gateway, or NAT may appear under a
different address and be denied. Conversely, a gateway that source-NATs public
traffic into an allowed LAN address can defeat this restriction: do not forward
public dashboard traffic through such a gateway.

Ensure LAN DNS resolves the hostname to the private Traefik LoadBalancer address.
Do not publish it through a public tunnel or router port-forward. If other apps
on this shared Service need public access, retain the dashboard middleware and
verify that their ingress path preserves real source addresses.

## Verify after applying

```sh
kubectl -n traefik wait --for=condition=Ready certificate/traefik-dashboard --timeout=180s
curl -I https://traefik-k8s.monkeyfaith.com/dashboard/
curl --user admin -I https://traefik-k8s.monkeyfaith.com/dashboard/
curl -I http://traefik-k8s.monkeyfaith.com/dashboard/
```

Replace `admin` with the username you selected; curl prompts for the password.
From the LAN, expect `401` without credentials and success with correct
credentials. HTTP must not serve the dashboard/API. From a reachable network
outside the allowlist, expect `403` even with correct credentials; if the service
is unreachable from there, a connection failure is also expected. Check `/api/`
as well as `/dashboard/`, and confirm other Traefik-hosted apps still work.
