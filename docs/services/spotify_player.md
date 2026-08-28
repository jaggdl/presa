# Spotify Player

Control and read the playback of your Spotify account across its available devices.

## Configuration

Like **Spotify**, this is an **OAuth service** — no API keys to type. It uses its own separate OAuth grant with a `user-modify-playback-state` scope, so it must be connected as its own service.

1. Register an app at the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) (or reuse an existing one) and note its **Client ID** and **Client Secret**.
2. In your Spotify app's settings, add the Presa redirect URI (an https URL, or `http://127.0.0.1` for local development; never `http://localhost`).
3. In Presa: **Credentials → Add credential**, choose provider **spotify**, give it a name, and paste the Client ID and Client Secret.
4. Add a **Spotify Player** service and, when prompted to connect, pick that credential and approve the OAuth consent.

The service is connected once it has acquired a grant and exposes its tools from then on. Tokens are acquired and refreshed automatically.
