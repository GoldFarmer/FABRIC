# Nexus Mods publication configuration

Keep machine-consumed, non-secret publishing defaults in a tracked release configuration such as `release\nexus-publish.json`, not only in narrative steering. Typical values are the game domain, public mod-page identifier, current main-file identifier, category, and a versioned Nexus display-name template. Include download or requirements-popup defaults only after confirming their author-side settings.

## Identifier handling

- A v1 `file_id` (the integer shown in the Nexus UI, page URLs, and v1 API responses) and a v3 mod-file ID are different identifiers in different ID spaces. `GET /v3/mod-files/{id}` returns 404 for a v1 file ID even when that file exists and is active. Never use a v1 file ID as a v3 mod-file ID.
- After a successful v3 publish, the response contains the new v3 file ID (`file.id` in `CreateModFileVersionSuccess`, `id` in `CreateModFileSuccess`). Capture and store this value; it is required for all subsequent `POST /mod-files/{id}/versions` calls.
- Use the v1 `GET /v1/games/{game_domain}/mods/{mod_id}/files.json` endpoint to inspect the current file inventory and confirm which file is active (MAIN category, `is_primary: true`) before a release. This endpoint uses the same `apikey` header as v3.
- Command-line overrides are useful for a one-off recovery or migration, but update the tracked configuration once the replacement value is verified.

## Safe configuration contents

Track public identifiers and publication defaults. Do not store API keys, bearer tokens, cookies, account recovery data, or other credentials in the configuration, repository, release archive, logs, or screenshots.

## Preflight integration

A publication tool should default to preflight mode: load this configuration, validate the local release archive and checksum, validate listing sources, and display the exact target and flags without reading credentials or making network requests. Its explicit publish mode should require a session-local credential and a confirmation gate, resolve identifiers again through the current API, create/upload/finalize/poll the upload session, create the selected file or version, append the changelog, and preserve a manual verification step after publication.

## Page-state review

Before every release, review the page title, short description, BBCode-rendered long description, category, tags, declared dependencies, file category, download options, primary-file selection, requirements-popup setting, changelog, and archive checksum. Some author-only settings are not reliably represented on the public page, so confirm them in the Nexus upload/dashboard interface.
