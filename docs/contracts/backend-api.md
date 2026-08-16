# Backend Contract

## Canonical source

Canonical FastAPI schema: `https://www.panor.tech/soundscape/api/openapi.json`.

`soundscape-openapi.json` is the pinned contract snapshot. It is updated only when the backend contract intentionally changes and tests/mappings are updated in the same change.

## Base URLs

- Soundscape API: `https://www.panor.tech/soundscape/api`
- Unified auth: `https://www.panor.tech/api/panor/auth`
- Relative media paths such as `/soundscape/uploads/...` resolve against `https://www.panor.tech`.

## Authentication

`POST /register` accepts `{username,email,password}`. `POST /login` accepts `{username,password}`. Both return `{token,user}`. `GET /me` accepts `Authorization: Bearer <token>`. Soundscape authenticated routes use the same bearer token.

The client has no alternate product-path fallback. The canonical route is live; release verification fails if the live OpenAPI no longer matches the pinned snapshot.

## Multipart publish

Required: `audio`.

Optional/declared fields: `cover`, `cover_url`, `title`, `description`, `lat`, `lng`, `location_name`, `category`, `prompt_text`, `tag_personal_social`, `tag_memory_present`, `is_public`.

Uploaded cover bytes take precedence over `cover_url`. AI cover responses already include the backend-generated watermarked media path.

## Error policy

- `401`: token absent/invalid; clear session after `/me` rejects it.
- `403`: ownership violation.
- `404`: resource missing.
- `422`: request contract mismatch.
- `503`: explicit upstream failure such as AI or auth unavailability.
- No status is converted into fabricated success data.
