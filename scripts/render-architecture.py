#!/usr/bin/env python3
"""Render a Secrets Manager architecture diagram from a Terraform plan JSON.

Shows each managed secret, the KMS key encrypting them, and a rotation Lambda
edge for any secret with rotation configured.

Usage:
    python scripts/render-architecture.py <plan.json> <output-path-no-ext>
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import Lambda
from diagrams.aws.security import KMS, SecretsManager


def load_resources(plan_path: Path) -> list[dict]:
    plan = json.loads(plan_path.read_text())
    root = plan.get("planned_values", {}).get("root_module", {})
    collected: list[dict] = []

    def walk(mod: dict) -> None:
        for r in mod.get("resources", []):
            collected.append(r)
        for child in mod.get("child_modules", []):
            walk(child)

    walk(root)
    return collected


def values(r: dict) -> dict:
    return r.get("values", {}) or {}


def render(plan_path: Path, out_no_ext: Path) -> None:
    resources = load_resources(plan_path)
    by_type: dict[str, list[dict]] = {}
    for r in resources:
        by_type.setdefault(r["type"], []).append(r)

    secrets = by_type.get("aws_secretsmanager_secret", [])
    if not secrets:
        raise SystemExit("No aws_secretsmanager_secret found in plan — nothing to render.")

    rotations = {
        r["address"].split('["')[-1].rstrip('"]')
        for r in by_type.get("aws_secretsmanager_secret_rotation", [])
    }
    policies = {
        r["address"].split('["')[-1].rstrip('"]')
        for r in by_type.get("aws_secretsmanager_secret_policy", [])
    }
    has_cmk = any(values(s).get("kms_key_id") for s in secrets)

    count = len(secrets)
    badges = [f"{count} secret{'s' if count != 1 else ''}"]
    if has_cmk:
        badges.append("CMK-encrypted")
    if rotations:
        badges.append(f"{len(rotations)} rotated")

    graph_attr = {
        "fontsize": "20",
        "splines": "ortho",
        "ranksep": "1.0",
        "nodesep": "0.5",
        "pad": "0.5",
    }

    out_no_ext.parent.mkdir(parents=True, exist_ok=True)
    with Diagram(
        f"terraform-aws-secretsmanager — {' · '.join(badges)}",
        filename=str(out_no_ext),
        show=False,
        direction="LR",
        outformat="png",
        graph_attr=graph_attr,
    ):
        kms = KMS("KMS key") if has_cmk else None
        rotator = Lambda("rotation\nLambda") if rotations else None

        with Cluster("Secrets Manager"):
            for s in secrets:
                v = values(s)
                key = s["address"].split('["')[-1].rstrip('"]')
                label = (v.get("name") or key).split("/")[-1]
                tags = []
                if key in rotations:
                    tags.append("rotated")
                if key in policies:
                    tags.append("shared")
                suffix = f"\n({', '.join(tags)})" if tags else ""
                node = SecretsManager(f"{label}{suffix}")
                if kms is not None:
                    kms >> Edge(style="dashed") >> node
                if rotator is not None and key in rotations:
                    rotator >> Edge(style="dotted", label="rotates") >> node


def main() -> None:
    if len(sys.argv) < 3:
        sys.stderr.write("Usage: render-architecture.py <plan.json> <output-path-without-ext>\n")
        sys.exit(2)
    render(Path(sys.argv[1]), Path(sys.argv[2]))


if __name__ == "__main__":
    main()
