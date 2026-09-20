#!/bin/zsh
# Creates an external-review archive without modifying project source files.
set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
OUTPUT_DIR="$PROJECT_ROOT/external-share-20260917"
ARCHIVE="$OUTPUT_DIR/external-share-sanitized.zip"
MANIFEST="$OUTPUT_DIR/SANITIZATION_MANIFEST.md"
STAGE_DIR="$(mktemp -d /private/tmp/external-share.XXXXXX)"
PAYLOAD_DIR="$STAGE_DIR/external-share-sanitized"
trap 'rm -rf "$STAGE_DIR"' EXIT

if [[ -e "$OUTPUT_DIR" ]]; then
  print -u2 "Refusing to overwrite existing output directory: $OUTPUT_DIR"
  exit 1
fi
mkdir -p "$PAYLOAD_DIR"

# Do not include VCS metadata, runtime caches, generated output, operational
# documentation, CI/GitHub metadata, or generated/cache data.
rsync -a \
  --exclude='.git/' \
  --exclude='.github/' \
  --exclude='.DS_Store' \
  --exclude='*.code-workspace' \
  --exclude='docs/' \
  --exclude='_doc_review/' \
  --exclude='ASTRA_VALIDATION_*.md' \
  --exclude='*.txt' \
  --exclude='temp/' \
  --exclude='**/.terraform/' \
  --exclude='**/.terragrunt-cache/' \
  --exclude='**/.terraform.lock.hcl' \
  --exclude='*.tfstate' \
  --exclude='*.tfstate.*' \
  --exclude='*.tfplan' \
  --exclude='.env' \
  --exclude='.env.*' \
  --exclude='*.tfvars' \
  --exclude='*.tfvars.json' \
  --exclude='*.pem' \
  --exclude='*.key' \
  --exclude='*.p12' \
  --exclude='*.pfx' \
  --exclude='*.jks' \
  --exclude='credentials' \
  --exclude='backend/target/' \
  --exclude='**/__pycache__/' \
  --exclude='share-output/' \
  --exclude='external-share-20260917/' \
  --exclude='scripts/create_external_share.sh' \
  --exclude='scripts/external_share_readme.md' \
  --exclude='scripts/external_share_manifest.md' \
  "$PROJECT_ROOT/" "$PAYLOAD_DIR/"

# Replace only values that can identify an AWS/Git account or function as
# credentials/secrets. Ordinary technical configuration (region, CIDR, AZ,
# versions, instance types, resource names, namespaces, module/dependency
# paths, tags, branches, etc.) is intentionally preserved.
find "$PAYLOAD_DIR" -type f \( \
  -name '*.md' -o -name '*.txt' -o -name '*.yaml' -o -name '*.yml' -o \
  -name '*.hcl' -o -name '*.tf' -o -name '*.json' -o -name '*.java' -o \
  -name '*.py' -o -name '*.xml' -o -name '*.properties' \) -print0 |
  xargs -0 perl -pi -e '
    s/\b\d{12}\b/<AWS_ACCOUNT_ID>/g;
    s/(arn:aws(?:-[a-z]+)?:[A-Za-z0-9-]*:[A-Za-z0-9-]*:)(?:\d{12})(:)/$1<AWS_ACCOUNT_ID>$2/g;
    s/(repository_owner\s*=\s*")[^"]+(")/$1<GIT_ACCOUNT>$2/g;
    s/(github_owner\s*=\s*")[^"]+(")/$1<GIT_ACCOUNT>$2/g;
    s/(repository_name\s*=\s*")[^"]+(")/$1<GIT_REPOSITORY>$2/g;
    s/(github_repository\s*=\s*")[^"]+(")/$1<GIT_REPOSITORY>$2/g;
    s#(https?://github\.com/)[^/[:space:]"]+/[^/[:space:]"]+#$1<GIT_ACCOUNT>/<GIT_REPOSITORY>#g;
    s/(AKIA|ASIA)[A-Z0-9]{16}/<AWS_ACCESS_KEY_ID>/g;
    s/((?:secret_access_key|aws_secret_access_key|github_token|token|password|webhook_secret)\s*[=:]\s*")[^"]+(")/$1<REDACTED_SECRET>$2/gi;
    s#-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----#<REDACTED_PRIVATE_KEY>#gs;
  '

cp "$PROJECT_ROOT/scripts/external_share_readme.md" "$PAYLOAD_DIR/README_EXTERNAL_SHARE.md"

mkdir -p "$OUTPUT_DIR"
cp "$PROJECT_ROOT/scripts/external_share_manifest.md" "$MANIFEST"

cp "$MANIFEST" "$PAYLOAD_DIR/SANITIZATION_MANIFEST.md"
(cd "$STAGE_DIR" && zip -qr "$ARCHIVE" "${PAYLOAD_DIR:t}")
shasum -a 256 "$ARCHIVE" > "$OUTPUT_DIR/external-share-sanitized.zip.sha256"

echo "Created: $ARCHIVE"
echo "Manifest: $MANIFEST"
