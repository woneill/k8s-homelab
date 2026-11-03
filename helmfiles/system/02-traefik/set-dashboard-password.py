#!/usr/bin/env python3
"""Store a dashboard BasicAuth credential in the SOPS-encrypted Helm values."""

import getpass
import json
from pathlib import Path
import subprocess


def main():
    path = Path(__file__).resolve().with_name("secrets.yaml")
    username = input("Dashboard username: ").strip()
    if not username or any(char in username for char in ":\r\n"):
        raise SystemExit("Username must be nonempty and contain no colon or newline.")
    password = getpass.getpass("Dashboard password: ")
    if not password or len(password.encode()) > 72 or any(char in password for char in "\r\n"):
        raise SystemExit("Password must be 1–72 UTF-8 bytes and contain no newline.")
    if password != getpass.getpass("Confirm password: "):
        raise SystemExit("Passwords do not match.")

    users = subprocess.check_output(
        ["htpasswd", "-niB", "-C", "12", username],
        input=password + "\n",
        text=True,
    ).strip()
    data = json.loads(subprocess.check_output(
        ["sops", "decrypt", "--output-type", "json", str(path)],
    ))
    objects = data.setdefault("extraObjects", [])
    secret = {
        "apiVersion": "v1",
        "kind": "Secret",
        "metadata": {"name": "traefik-dashboard-auth"},
        "type": "Opaque",
        "stringData": {"users": users},
    }
    for index, obj in enumerate(objects):
        if obj.get("kind") == "Secret" and obj.get("metadata", {}).get("name") == "traefik-dashboard-auth":
            objects[index] = secret
            break
    else:
        objects.append(secret)

    encrypted = subprocess.check_output(
        ["sops", "encrypt", "--input-type", "json", "--output-type", "yaml",
         "--filename-override", str(path), "/dev/stdin"],
        input=json.dumps(data).encode(),
    )
    path.write_bytes(encrypted)
    print("Updated secrets.yaml with the encrypted bcrypt credential. Apply the Helm release to activate it.")


if __name__ == "__main__":
    main()
