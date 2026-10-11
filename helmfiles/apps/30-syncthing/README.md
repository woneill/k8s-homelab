# Syncthing

This local chart is based on `woneill/syncthing` version `0.3.5`. Helmfile uses
`chart: ./chart`; publishing a separate chart is no longer required.

Chart sources, defaults, unit tests, and CI values live under `chart/`.
The outer `values.yaml` holds homelab-specific overrides; `secrets.yaml` holds
encrypted ingress and TLS settings.

## Image updates

`image.repository` and `image.tag` in `chart/values.yaml` are the authoritative image
settings. Renovate's built-in `helm-values` manager updates the tag using the
inherited `woneill/.github` configuration. Application-version labels derive
from the tag, so there is no separate `Chart.yaml` application version to update.
The chart version remains `0.3.5` to preserve existing chart labels during the
migration; change it when updating chart templates if needed.

## Tests

The `Syncthing Chart` GitHub Actions workflow runs on pull requests, merge-queue
entries, and manual dispatch. It follows the former chart repository's approach:
`ct lint` runs YAML/schema validation, Helm linting, and helm-unittest suites;
`ct install` installs the chart in a disposable kind cluster and runs its Helm
connectivity test hook. No homelab credentials or SOPS secrets are used.

CI uses `chart/ci/default-values.yaml`: ClusterIP, no ingress, and a 1Gi claim on kind's
`standard` storage class. These overrides are not used by the deployment Helmfile.
Chart-version increments are not required for image-tag updates.

With helm-unittest installed, run template unit tests locally:

```sh
helm unittest -f 'tests/*_test.yaml' helmfiles/apps/30-syncthing/chart
```

With chart-testing, yamllint, Yamale, and helm-unittest installed:

```sh
ct lint --config .github/ct.yaml
```

Only run the integration command against a disposable cluster, not the homelab:

```sh
kind create cluster --name syncthing-ci
ct install --config .github/ct.yaml
kind delete cluster --name syncthing-ci
```

To require this check before merging, configure the `Lint and test Syncthing`
status check in the repository's GitHub ruleset or branch protection. The inherited
Renovate preset currently allows automerging without required tests.

## Deployment

Ingress and TLS overrides remain in the existing SOPS-encrypted `secrets.yaml`.
The chart defaults to an 8Gi claim; the outer `values.yaml` preserves the homelab's
20Gi override. The release name, namespace, and persistent claim remain
`syncthing`. The 20Gi RWO volume is mounted at `/var/syncthing`; `Recreate` avoids overlapping pods
using that volume and causes brief downtime on image updates.

From the repository root:

```sh
helmfile -f helmfiles/apps/30-syncthing/helmfile.yaml diff
helmfile -f helmfiles/apps/30-syncthing/helmfile.yaml apply
```

Have a current backup or snapshot before upgrades. After deployment, verify the
pod is ready and Syncthing peers resume synchronization.
