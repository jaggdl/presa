# Spotify

Pull your Spotify listening data into a workspace. Add a Spotify **OAuth client** and authorize your account, and Presa exposes tools for your profile, your top artists and tracks, your recently played tracks, your saved library, and your playlists as callable workspace tools. Built against the [Spotify Web API](https://developer.spotify.com/documentation/web-api) (Authorization Code flow).

## Configuration

This kind is an **OAuth service** — you don't type API keys. Instead:

1. Register an app at the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) and note its **Client ID** and **Client Secret**.
2. In your Spotify app's settings, add the Presa redirect URI (the callback of this Presa install — an https URL, or `http://127.0.0.1` for local development; never `http://localhost`).
3. In Presa: **Credentials → Add credential**, choose provider **spotify**, give it a name, and paste the Client ID and Client Secret.
4. Add a **Spotify** service and, when prompted to connect, pick that credential and approve the OAuth consent.

The service is connected once it has acquired a grant, and exposes its tools from then on. Tokens are acquired and refreshed automatically.

## Prerequisites

- A Spotify Developer app with a client ID and secret, and the Presa redirect URI whitelisted.
- A Spotify account to authorize.

## Scope

Requests request only the minimum scope for the exposed features: `user-read-private` (profile), `user-top-read` (top items), `user-read-recently-played` (recently played), `user-library-read` (saved tracks), and `playlist-read-private` (playlists). Playback control would require additional scopes and is intentionally not requested.

## Notes

- Connectivity is the acquired OAuth grant: a service is "connected" once it has one, and tokens refresh on demand.
- Redirect callback is preconfigured; only your client credentials are required.
- 429 rate-limit responses are handled with exponential backoff, honoring Spotify's `Retry-After` header.