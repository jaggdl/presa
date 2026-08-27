# Google Places

Pull curated place data into a workspace with [Google Places API (New)](https://developers.google.com/maps/documentation/places/web-service): text search for places, detailed place lookups by place ID, and place photo metadata. Power location-aware agents ("what time does that restaurant close?", "find EV chargers near me", "what's the rating of this cafe?").

## Configuration

This kind is an **API-key service** — no OAuth. Instead:

1. Create a Google Cloud project and enable the **Places API (New)** service (make sure you enable the current **(New)** version, not the legacy Places API), then set up billing ([get an API key](https://developers.google.com/maps/documentation/places/web-service/get-api-key)).
2. Restrict the key to the Places API and, if possible, to your server's IP/HTTP referrers.
3. In Presa: add a **Places** service and paste the API key into the `api_key` field.

## Prerequisites

- A Google Cloud project with the **Places API (New)** service enabled and billing attached (enable the current New version, not the legacy Places API).
- A Google Maps Platform **API key** (kept server-side; it is sent as the `X-Goog-Api-Key` header, never exposed to clients).

## Tools

- **text_search** — free-text search for places (`places:searchText`), with optional page size/token, place-type bias, language/region, open-now, minimum rating, and rank preferences.
- **nearby_search** — find places around a location (`places:searchNearby`), by center latitude/longitude + radius in meters, with optional included/excluded (primary) place types, max results, and POPULARITY/DISTANCE ranking.
- **place_details** — full detail for a place ID (`places/{placeId}`), including address, website, phone, rating, opening hours, and photos.
- **place_photos** — photo metadata and a usable `photoUri` for a photo resource name from the `photos[]` array. Photo names expire, so always fetch them fresh from a recent search/details response.
- **place_autocomplete** — type-ahead place/query predictions (`places:autocomplete`), with optional primary-type and region filters, query predictions, an origin for distances, location bias/restriction, and a `session_token` to group calls into a session for billing.

## Notes

- The tools call the current **Places API (New)** endpoints (`places:searchText`, `places/{placeId}`, `places/{placeId}/photos/.../media`). Make sure the service enabled on your project is **Places API (New)** — the legacy Places API uses different endpoints and auth and will not work.
- Every request sends an `X-Goog-FieldMask` header, which controls the exact place fields returned (and billed). Each tool exposes an optional `fields` argument to tailor the mask; defaults request a sensible core set. There is no default mask in the API — omitting it is an error, so the tools always send one.
- Results are IP-biased when no explicit location is given. Include a location in the query text (e.g. "coffee in San Francisco") for best results.
- 429 rate-limit responses are retried with exponential backoff, honoring Google's `Retry-After` header.
- Displaying place data is subject to the [Places API policies and attribution requirements](https://developers.google.com/maps/documentation/places/web-service/policies); photo `authorAttributions` must be shown where required.
- "Test connection" issues the cheapest possible request: a single-result text search for the free ID-only field.