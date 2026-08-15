# Nexus Mods API

Nexus Mods provides two API generations with different ID spaces and capabilities. Use the right one for each task.

## v3 API (upload and publishing)

Nexus Mods publishes an OpenAPI 3 specification at `https://api.nexusmods.com/openapi.yaml`. The current v3 API base is `https://api.nexusmods.com/v3`. Use the current specification as the source of truth before building or changing an integration; the API surface is versioned and its endpoint stability is explicitly labeled.

### Stability and change management

- **Stable** endpoints are production-ready and may receive additive, optional fields. Deprecated stable fields/endpoints receive at least 90 days of notice and migration guidance.
- **Beta** endpoints are feature-complete but may change before stabilization; their deprecation period is at least 10 days.
- **Experimental** endpoints may change substantially or be removed. Do not make a release workflow depend on them without a maintained fallback and a human review step.
- Prefer the non-deprecated replacement endpoint when documentation marks an older endpoint as deprecated.

### Authentication and safety

- Protected operations accept `ApiKeyAuth` or `BearerJwtAuth`. The official upload action supplies an API key through the `apikey` request header.
- Treat API keys and bearer tokens as secrets. Keep them outside the repository, release archives, logs, and screenshots; supply them through a secure local environment or approved secret store.
- Read operations may be useful for verification, but writes can create or alter public Nexus content. Require explicit human approval immediately before initiating an upload or publishing a file/version.

### Upload lifecycle

The API separates binary upload from mod-file publication:

1. Create an upload session with the exact filename and byte size.
2. Upload the archive to Nexus's returned presigned URL. Single-part upload is intended for files up to 100 MiB and requires the exact signed `Content-Disposition: attachment; filename="<filename>"` header.
3. For files larger than 100 MiB, use the multipart session, upload every part, record each returned ETag, and complete the multipart upload according to the Amazon S3 multipart protocol.
4. Finalise the upload session.
5. Poll the upload state until it is `available`; only then use its upload ID to create a mod file or file version.

An upload is not automatically a public mod file. Keep the archive, file metadata, version, changelog, category, and download settings under explicit release review before the final API call.

### Mod files and versions

- Create a new mod file with `POST /mod-files` only for a new file entry.
- Add a version to an existing mod file with `POST /mod-files/{id}/versions`; this is the current replacement for the deprecated update-group version endpoint.
- File creation/version requests use a finalized `upload_id`, file name, version, category (`main`, `optional`, or `miscellaneous`), and mod-manager/requirements flags. Validate API constraints such as the 50-character file-name/version limits before submitting.
- Changelog and dependency-management endpoints exist, but are Experimental; automate them only after validating the current schema against the OpenAPI specification.

### v3 ID space

The v3 API uses its own internal IDs for mod files. These are **not** the same integers as the v1 `file_id` values shown in the Nexus UI, page URLs, and v1 API responses. `GET /v3/mod-files/{id}` will return 404 for a v1 file ID even when the file exists and is active. There is no v3 endpoint to list all files for a mod or to look up a v3 file ID by its v1 equivalent. After a successful v3 publish, capture the returned `file.id` (from `CreateModFileVersionSuccess` or `CreateModFileSuccess`) and store it — that is the v3 ID needed for subsequent `POST /mod-files/{id}/versions` calls.

## v1 API (read-only metadata)

The v1 API base is `https://api.nexusmods.com/v1`. Its file IDs are the integers shown in the Nexus UI and page URLs. Use v1 for read-only preflight checks and file inventory queries; do not use it for upload or publishing.

Key endpoints for release tooling:

- `GET /v1/games/{game_domain}/mods/{mod_id}/files.json` — lists all files for a mod, including `file_id`, `category_name` (`MAIN`, `OPTIONAL`, `ARCHIVED`), `is_primary`, `version`, and a `file_updates` chain showing which file superseded which.
- `GET /v1/games/{game_domain}/mods/{mod_id}/files/{file_id}.json` — returns details for a single file by its v1 ID.

Authentication uses the same `apikey` header as v3.

## Workflow guidance

Use the API to reduce repetitive release work, not to bypass release validation. A safe publish workflow is: package and verify locally, review the exact release archive and listing fields, create/finalize the v3 upload, wait for availability, create the new file or version, capture the returned v3 file ID, then verify the resulting Nexus page manually. Nexus also links an official GitHub Action and sample workflow; evaluate them against the current API documentation before adopting either.

## Scope boundaries

Collection endpoints manage Nexus collections and are separate from an author's mod files. Vortex endpoints expose extension/theme/translation discovery and are not a general-purpose mod publishing interface.
