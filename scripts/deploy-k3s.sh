#!/usr/bin/env bash
set -euo pipefail

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

: "${CHART_URI:?Missing CHART_URI}"
: "${FRONTEND_IMAGE:?Missing FRONTEND_IMAGE}"
: "${WORKER_IMAGE:?Missing WORKER_IMAGE}"

WORKDIR=$(mktemp -d /tmp/skywatch-deploy.XXXXXXXX)
trap 'rm -rf "$WORKDIR"' EXIT

K=(k3s kubectl)

echo "===== DOWNLOAD CHART ====="
aws s3 cp "$CHART_URI" "$WORKDIR/chart.tgz"

echo "===== VERIFY EXISTING RELEASE ====="
test "$(helm status skywatch -n skywatch -o json | python3 -c \
  'import json,sys; print(json.load(sys.stdin)["info"]["status"])')" = "deployed"

echo "===== RECORD RABBITMQ STATE ====="
RABBIT_UID=$("${K[@]}" -n skywatch get pod -l app=rabbitmq \
  -o jsonpath='{.items[0].metadata.uid}')

RABBIT_TEMPLATE=$("${K[@]}" -n skywatch get deployment rabbitmq \
  -o jsonpath='{.spec.template}' | sha256sum | cut -d' ' -f1)

test -n "$RABBIT_UID"

echo "===== RENDER CURRENT AND PROPOSED MANIFESTS ====="
helm get manifest skywatch -n skywatch > "$WORKDIR/before.yaml"

helm get values skywatch -n skywatch -o yaml > "$WORKDIR/values.yaml"

helm template skywatch "$WORKDIR/chart.tgz" \
  -n skywatch \
  -f "$WORKDIR/values.yaml" \
  --set-string frontend.image="$FRONTEND_IMAGE" \
  --set-string worker.image="$WORKER_IMAGE" \
  > "$WORKDIR/after.yaml"

echo "===== PROTECT RABBITMQ ====="
python3 - "$WORKDIR/before.yaml" "$WORKDIR/after.yaml" <<'PYTHON_CHECK'
import sys
import yaml

EXPECTED = {
    ("Deployment", "rabbitmq"),
    ("Service", "rabbitmq"),
}

def extract(path):
    with open(path, encoding="utf-8") as stream:
        documents = yaml.safe_load_all(stream)
        result = {}
        for document in documents:
            if not isinstance(document, dict):
                continue
            key = (
                document.get("kind"),
                document.get("metadata", {}).get("name"),
            )
            if key in EXPECTED:
                if key in result:
                    raise SystemExit(f"ERROR: Duplicate resource: {key}")
                result[key] = document
        return result

before = extract(sys.argv[1])
after = extract(sys.argv[2])

if set(before) != EXPECTED or set(after) != EXPECTED:
    raise SystemExit("ERROR: RabbitMQ resources missing")

if before != after:
    raise SystemExit(
        "ERROR: RabbitMQ manifests differ. Deployment blocked."
    )

print("PASS: RabbitMQ manifests unchanged")
PYTHON_CHECK

echo "===== DEPLOY FRONTEND AND WORKER ====="
helm upgrade skywatch "$WORKDIR/chart.tgz" \
  -n skywatch \
  --reuse-values \
  --set-string frontend.image="$FRONTEND_IMAGE" \
  --set-string worker.image="$WORKER_IMAGE" \
  --atomic \
  --wait \
  --timeout 5m

echo "===== VERIFY ROLLOUTS ====="
"${K[@]}" -n skywatch rollout status \
  deployment/skywatch-frontend --timeout=180s

"${K[@]}" -n skywatch rollout status \
  deployment/skywatch-worker --timeout=180s

echo "===== VERIFY IMAGE VERSIONS ====="
ACTUAL_FRONTEND=$("${K[@]}" -n skywatch get deployment \
  skywatch-frontend \
  -o jsonpath='{.spec.template.spec.containers[0].image}')

ACTUAL_WORKER=$("${K[@]}" -n skywatch get deployment \
  skywatch-worker \
  -o jsonpath='{.spec.template.spec.containers[0].image}')

test "$ACTUAL_FRONTEND" = "$FRONTEND_IMAGE"
test "$ACTUAL_WORKER" = "$WORKER_IMAGE"

echo "===== FRONTEND SMOKE TEST ====="
"${K[@]}" -n skywatch exec deployment/skywatch-frontend -- \
  python -c '
import urllib.request

with urllib.request.urlopen(
    "http://127.0.0.1:5000/", timeout=15
) as response:
    assert response.status == 200
    assert b"Hello from SkyWatch!" in response.read()

print("PASS: Frontend HTTP")
'

echo "===== VERIFY RABBITMQ WAS NOT RESTARTED ====="
NEW_RABBIT_UID=$("${K[@]}" -n skywatch get pod -l app=rabbitmq \
  -o jsonpath='{.items[0].metadata.uid}')

NEW_RABBIT_TEMPLATE=$("${K[@]}" -n skywatch get deployment rabbitmq \
  -o jsonpath='{.spec.template}' | sha256sum | cut -d' ' -f1)

test "$RABBIT_UID" = "$NEW_RABBIT_UID"
test "$RABBIT_TEMPLATE" = "$NEW_RABBIT_TEMPLATE"

echo "===== FINAL STATUS ====="
"${K[@]}" -n skywatch get pods -o wide

echo "SUCCESS: SkyWatch deployed and RabbitMQ unchanged"
