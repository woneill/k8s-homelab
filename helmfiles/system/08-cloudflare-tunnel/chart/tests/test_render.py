"""Offline Helm render tests. Build chart dependencies before running."""

import base64
import json
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


CHART = Path(__file__).resolve().parents[1]
TUNNEL_ID = "11111111-1111-4111-8111-111111111111"


def synthetic_values():
    return {
        "credentials": {
            "accountTag": "0" * 32,
            "tunnelSecret": base64.b64encode(bytes(32)).decode(),
        },
        "cloudflared": {
            "tunnelConfig": {"name": TUNNEL_ID},
            "ingress": [{"service": "http_status:404"}],
        },
    }


def render(values, command="template", workload_values=False):
    with tempfile.TemporaryDirectory(prefix="cloudflared-wrapper-test-") as tmp:
        values_file = Path(tmp) / "values.json"
        values_file.write_text(json.dumps(values))
        args = ["helm", command]
        if command == "template":
            args.append("cloudflare-tunnel")
        args.append(str(CHART))
        if workload_values:
            args.extend(["--values", str(CHART.parent / "values.yaml")])
        args.extend(["--values", str(values_file)])
        return subprocess.run(args, capture_output=True, text=True, timeout=30)


class RenderTests(unittest.TestCase):
    def test_credentials_only_workload(self):
        values = synthetic_values()
        result = render(values)
        self.assertEqual(result.returncode, 0, result.stderr)
        documents = result.stdout.split("\n---")
        secrets = [doc for doc in documents if "\nkind: Secret\n" in doc]
        self.assertEqual(len(secrets), 1)
        secret = secrets[0]
        self.assertIn('name: "cloudflare-tunnel-credentials"', secret)
        self.assertNotIn("cert.pem:", secret)
        encoded = re.search(r'^  "credentials.json": "([^"]+)"$', secret, re.M)
        self.assertIsNotNone(encoded)
        self.assertEqual(
            json.loads(base64.b64decode(encoded.group(1))),
            {
                "AccountTag": values["credentials"]["accountTag"],
                "TunnelID": TUNNEL_ID,
                "TunnelSecret": values["credentials"]["tunnelSecret"],
            },
        )
        deployment = next(doc for doc in documents if "kind: Deployment\n" in doc)
        self.assertIn("name: cloudflare-tunnel-cloudflared\n", deployment)
        self.assertIn("replicas: 2", deployment)
        self.assertIn("cloudflare/cloudflared:2026.9.3", deployment)
        self.assertEqual(deployment.count("name: cloudflare-tunnel-credentials"), 2)
        self.assertIn("/etc/cloudflared/creds/cert.pem", deployment)
        config = next(doc for doc in documents if "kind: ConfigMap\n" in doc)
        self.assertIn(TUNNEL_ID, config)
        self.assertIn("/etc/cloudflared/creds/credentials.json", config)
        self.assertIn("http_status:404", config)
        self.assertTrue(any("kind: PodDisruptionBudget\n" in doc for doc in documents))

    def test_release_workload_values(self):
        result = render(synthetic_values(), workload_values=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        documents = result.stdout.split("\n---")
        deployment = next(doc for doc in documents if "kind: Deployment\n" in doc)
        self.assertIn("replicas: 2", deployment)
        self.assertNotIn("tolerations:", deployment)
        self.assertIn("podAntiAffinity:", deployment)
        self.assertIn("topologyKey: kubernetes.io/hostname", deployment)
        self.assertIn("runAsNonRoot: true", deployment)
        self.assertIn("runAsUser: 65532", deployment)
        self.assertIn("failureThreshold: 6", deployment)
        self.assertIn("initialDelaySeconds: 30", deployment)
        service_account = next(
            doc for doc in documents if "kind: ServiceAccount\n" in doc
        )
        self.assertIn("automountServiceAccountToken: false", service_account)

    def test_required_credentials(self):
        for key in ("accountTag", "tunnelSecret"):
            with self.subTest(key=key):
                values = synthetic_values()
                values["credentials"][key] = ""
                result = render(values)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("credentials." + key + " is required", result.stderr)

    def test_requires_uuid(self):
        values = synthetic_values()
        values["cloudflared"]["tunnelConfig"]["name"] = "display-name"
        result = render(values)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must be a UUID", result.stderr)

    def test_requires_matching_secret_references(self):
        values = synthetic_values()
        values["cloudflared"]["tunnelSecrets"] = {
            "existingPemFileSecret": {"name": "different-secret"},
        }
        result = render(values)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("both existing-Secret references must point", result.stderr)

    def test_lint(self):
        result = render(synthetic_values(), command="lint")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
