# Noema S3-Compatible Storage Compatibility

> **For Hermes:** This document records the current Forem-derived storage posture and the patch decision for S3-compatible object storage. Do not commit credentials. Live endpoint testing belongs in a separate spike with throwaway credentials or approved Secret handoff.

## Goal

Determine whether Noema can use S3-compatible object storage for uploads/media without code changes, and define the minimal safe patch if not.

## Current Finding

Current Rails upload storage is not yet proven for generic S3-compatible endpoints.

From runtime inventory:

- CarrierWave production storage switches to fog/AWS only when `RAILS_ENV=production`, `FILE_STORAGE_LOCATION != file`, and `AWS_ID` is present.
- Current upload env vars include `AWS_ID`, `AWS_SECRET`, `AWS_BUCKET_NAME`, `AWS_UPLOAD_REGION`, `AWS_S3_INPUT_BUCKET`, `AWS_S3_VIDEO_ID`, `AWS_S3_VIDEO_KEY`.
- Current CarrierWave credentials use AWS provider, access key, secret, and region.
- No explicit endpoint URL was found in the runtime inventory.
- No explicit path-style / force-path-style option was found in the runtime inventory.
- `AgentSessions::S3Storage` has the same AWS-only shape.

## Required PoC Env Vars

Existing vars:

```text
FILE_STORAGE_LOCATION=fog
AWS_ID
AWS_SECRET
AWS_BUCKET_NAME
AWS_UPLOAD_REGION
```

Required S3-compatible additions:

```text
AWS_ENDPOINT_URL
AWS_FORCE_PATH_STYLE
AWS_DEFAULT_REGION
```

For the current intended object storage posture, the Secret/config handoff should support:

```text
AWS_BUCKET_NAME=mattermost or noema-specific bucket once chosen
AWS_UPLOAD_REGION=ap-southeast-1
AWS_ENDPOINT_URL=https://s3.ap-southeast-1.onidel.cloud
AWS_FORCE_PATH_STYLE=true|false  # verify with provider
```

Use a Noema-specific bucket or prefix decision before production. Do not assume the Mattermost bucket should be reused for Noema uploads.

## Patch Decision

Patch has been applied for generic S3-compatible endpoints.

Minimum patch requirements:

1. Preserve native AWS behavior when `AWS_ENDPOINT_URL` is unset. — implemented by omitting fog `endpoint`/`path_style` keys unless configured.
2. Add endpoint override to CarrierWave/fog config when `AWS_ENDPOINT_URL` is present. — implemented in `CarrierWaveInitializer.s3_fog_credentials`.
3. Add path-style/force-path-style support when `AWS_FORCE_PATH_STYLE=true`. — implemented with Rails boolean casting.
4. Apply equivalent endpoint/path-style support to `AgentSessions::S3Storage`. — implemented in its fog credentials.
5. Add tests for config object construction without real credentials. — covered by initializer/service specs; no bucket access.
6. `deploy/k8s/base/configmap.yaml` carries only non-secret storage knobs (`FILE_STORAGE_LOCATION`, region, endpoint, path-style). Credentials and bucket ownership still belong in `noema-runtime-secrets` or approved GitOps secret tooling.

## Files to Inspect/Patch

Use these inventory references when opening the implementation branch:

| Legacy file | Target concern |
| --- | --- |
| `config/initializers/carrierwave.rb` | upload storage config |
| `config/initializers/carrierwave_monkeypatch.rb` | runtime-config edge case |
| `app/services/agent_sessions/s3_storage.rb` | agent session object storage |
| `.env_sample` | env var documentation |
| uploaders under `app/uploaders/**` | behavior reference |

## Regression Test Shape

Tests should not hit a real bucket. They should verify config construction:

- no endpoint when `AWS_ENDPOINT_URL` unset;
- endpoint included when set;
- path-style flag parsed as boolean;
- AWS defaults still work;
- `AgentSessions::S3Storage` uses the same endpoint behavior.

## Manual Smoke Test Shape

After patch and approved credentials:

1. Deploy or run against MinIO/approved S3-compatible endpoint.
2. Upload a small image through real application path.
3. Confirm object exists in bucket.
4. Confirm rendered URL/proxy path works.
5. Delete test object or use a disposable prefix.

## Risks

- Bucket reuse can cause data ownership confusion. Prefer a Noema-specific bucket/prefix.
- Path-style requirements vary by provider.
- Some fog/AWS SDK versions use different option names for endpoint/path-style; verified against `fog-aws` 3.21.0 source that `endpoint` and `path_style` are recognized storage options.
- Upload success is not enough; rendered media URLs and imgproxy behavior need separate browser verification.
