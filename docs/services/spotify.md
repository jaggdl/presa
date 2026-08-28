# Spotify

Pull your Spotify listening data into a workspace.

## Configuration

This kind is an **OAuth service** — you don't type API keys. Instead:

1. Register an app at the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) and note its **Client ID** and **Client Secret**.
2. In your Spotify app's settings, add the Presa redirect URI (the callback of this Presa install — an https URL, or `http://127.0.0.1` for local development; never `http://localhost`).
3. In Presa: **Credentials → Add credential**, choose provider **spotify**, give it a name, and paste the Client ID and Client Secret.
4. Add a **Spotify** service and, when prompted to connect, pick that credential and approve the OAuth consent.

The service is connected once it has acquired a grant, and exposes its tools from then on. Tokens are acquired and refreshed automatically.