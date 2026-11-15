# Cloudflare Tunnel wrapper

The adjacent Helmfile targets this wrapper. The migration was deployed on
2026-11-15 to `admin@homelab`, namespace `cloudflare`, retaining release
`cloudflare-tunnel`. Helm revision 11 uses this wrapper and upstream chart 2.2.19
with image 2026.9.3. The temporary candidate was removed before the upgrade.

The wrapper depends on `community-charts/cloudflared` at the version pinned in
`Chart.yaml` and `Chart.lock`. It adds one Helm-managed Secret containing only
`credentials.json`. It does not copy or patch upstream templates.

## Values

The adjacent SOPS-encrypted `secrets.yaml` supplies:

- `credentials.accountTag`: the existing `cloudflare.account`.
- `credentials.tunnelSecret`: the existing `cloudflare.secret`, unchanged.
- `cloudflared.tunnelConfig.name`: the existing `cloudflare.tunnelId` UUID.

All upstream values belong under `cloudflared`, including `ingress` and
`tunnelConfig.warpRouting`. The wrapper defaults to a two-replica Deployment.
The encrypted values preserve the existing ingress order and WARP setting and
explicitly include the old chart's implicit final `http_status:404` rule. The
adjacent `values.yaml` preserves preferred node anti-affinity and empty
tolerations, disables ServiceAccount token automount, and relaxes liveness probe
timing. The image tag follows the upstream chart's appVersion rather than a
permanent override. Scoped Helmfile defaults enable atomic upgrades, cleanup on
failure, and a 300-second readiness timeout. Helmfile 1.8.3 maps `atomic: true` to
Helm 4's `--rollback-on-failure`; older tool versions need compatibility review.

Both upstream existing-Secret references intentionally point at the same
wrapper-managed Secret. Chart 2.2.19 projects that Secret twice without requiring
a `cert.pem` key. Cloudflared 2026.9.3 was tested with synthetic credentials and
networking disabled: it reached tunnel startup without the certificate and then
failed at network discovery, as expected. Cluster validation also passed: both
replicas consumed the projected Secret, became Ready on separate nodes, and
registered four Cloudflare connections each. Replacing one replica restored two
Ready replicas while the survivor remained Ready at every observed check. The
old chart's resources were removed. All three applications passed user testing
with the candidate present; post-switch application and any WARP checks remain
manual.

The UUID is the single source for both the tunnel configuration and credentials
JSON. The Secret stores the tunnel secret in its existing encoding, not decoded
or encoded a second time. Kubernetes Secret base64 encoding is not encryption;
do not commit plaintext production values or rendered manifests.

The chart does not checksum credentials into the pod template. After a
credentials-only change, explicitly restart the Deployment. Upstream ConfigMap
names and the default Secret name are fixed; do not install two copies into the
same namespace without reviewing ownership conflicts.

## Rollback

Revision 10 retains the previous chart and values in Helm history. If required:

```sh
helm rollback cloudflare-tunnel 10 --kube-context admin@homelab --namespace cloudflare --wait=watcher --timeout 5m
```

Rollback can interrupt connections. It does not revert the repository files;
reconcile the Helmfile configuration before a subsequent apply or sync.

## Local validation

From this directory:

```sh
helm repo add community-charts https://community-charts.github.io/helm-charts
helm dependency build .
python3 -B tests/test_render.py
```

The tests use synthetic values only and never access Kubernetes. Dependency
archives in `charts/` are ignored by Git; commit the dependency lock file.
