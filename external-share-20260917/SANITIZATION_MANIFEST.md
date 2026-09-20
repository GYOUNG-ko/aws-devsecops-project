# External-share sanitization manifest

The source workspace was not edited. The archive was built from a temporary copy.

## Excluded

- Version-control and collaboration metadata: `.git/`, `.github/`, workspace files, `.DS_Store`
- Operational material: `docs/`, `ASTRA_VALIDATION_*.md`, `irsa-test.txt`, `종료전화확인.txt`, `temp/`
- Terraform lock files, Terraform/Terragrunt caches, state, and plans
- Credentials and certificates: `.env*`, `*.tfvars*`, `credentials`, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.jks`
- Generated artifacts: `backend/target/`, Python `__pycache__/`

## Retained as redacted structure

- `live/**/*.hcl`: included with every quoted literal replaced by `<REDACTED_HCL_VALUE>`; AWS account IDs and private-network values are also replaced.

## Replaced in retained text files

- 12-digit AWS account IDs → `<AWS_ACCOUNT_ID>`
- RFC1918 private IPv4 addresses/CIDRs → `<PRIVATE_NETWORK>`
- Email addresses → `<EMAIL_REDACTED>`
- Literal PostgreSQL/MySQL JDBC endpoints → `<DATABASE_ENDPOINT_REDACTED>`

## Notes

The package is intentionally non-deployable. Secrets must be supplied through the recipient's own secret-management process.
