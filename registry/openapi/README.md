# OpenAPI presets

Checked-in, self-contained presets that seed reusable `OpenapiKind`s — one YAML
file per service, plus an optional icon under `registry/icons/`. A preset
surfaces in the service picker and search as an installable tile; installing it
(`POST /registry/openapi/:name/install`) parses the spec URL, generates the
kind's definition, persists the `OpenapiKind`, and redirects to its
new-service page.

Adding a service is just dropping a `<namespace>.yml` here (and, ideally, an
icon at `registry/icons/<namespace>.jpg`). The loader (`Registry::Openapi`)
does the rest — no Ruby subclass needed.

## File layout

```
registry/
├── openapi/
│   ├── immich.yml
│   ├── jellyfin.yml
│   └── nextcloud.yml
└── icons/
    ├── immich.png
    └── jellyfin.jpg
```

## Fields

| Field       | Required | Description |
|-------------|----------|-------------|
| `title`     | yes      | User-facing product name (shown on the card and the kind). |
| `namespace` | yes      | Machine kind. Unique per team; must match `/[a-z0-9_]/`. |
| `category`  | yes      | `Service` domain category shown on the card (e.g. `media`, `productivity`). |
| `spec_url`  | yes      | URL of the OpenAPI 3.x document used to generate the kind's definition. |
| `base_url`  | no       | Default base URL, used when a service doesn't override it. |
| `health_op` | no       | Operation (by `operationId`) used for "Test connection". Prefer an **authenticated** operation so the credential is validated too. |
| `credential`| no       | Credential-transmission override for specs whose declared scheme is wrong against the real server (see below). |
| `description` | no     | Markdown description shown on the card / service header (same shape as `docs/services/*.md`; a leading top-level heading is dropped when rendered). |

## Example

```yaml
title: Immich
namespace: immich
category: media
spec_url: https://raw.githubusercontent.com/immich-app/immich/refs/heads/main/open-api/immich-openapi-specs.json
base_url: http://localhost:2283/api
health_op: getAuthStatus
description: |
  # Immich

  Self-hosted photo and video backup, at scale.
```

## Icon

Icons live in `registry/icons/` and are resolved by convention —
`registry/icons/<namespace>.<ext>` — so the YAML doesn't name its own asset.
Any of `jpg jpeg png svg webp ico gif` works (square, ~1024px recommended).
On install the checked-in file is attached to the kind via Active Storage
(rather than downloaded from the base URL host, which may be unreachable from
the app for self-hosted presets).

## The `credential` override

Some specs declare a security scheme that doesn't match the live server. For
example, Jellyfin's spec says the API key goes in the `Authorization` header,
but the server actually ignores that and wants `X-Emby-Token`. Rather than
patch the spec, a preset can override how the credential is transmitted:

```yaml
credential:
  scheme: CustomAuthentication  # the security scheme name in the spec
  in: header                    # header | query | cookie
  param_name: X-Emby-Token      # header/query/cookie name to send the key in
```

At install the loader rewrites that scheme's slot in the generated definition
(`definition["security"]["CustomAuthentication"]`) to use `param_name` in the
given location, so the generated tools and health check send the credential
correctly. Omit `credential` when the spec's scheme is already correct.

## Notes

- The `definition` payload is generated from `spec_url` at install time; it is
  **not** stored in this file.
- `health_op` values are matched against the generated definition's
  `operationId` (e.g. Immich's `/auth/status` → `getAuthStatus`).
- A preset whose namespace already has an installed `OpenapiKind` is excluded
  from the picker tiles (it's offered as a real kind instead).
