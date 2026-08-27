# Gmail

Control a Gmail account from a workspace (send/read mail) using Google OAuth2.

Unlike services authenticated by a typed API key, Gmail uses **bring-your-own OAuth**: you register a Google OAuth client and authorize a Google account, and the service is created with the resulting grant. You only do this once per service; Presa stores the tokens and refreshes them for you.

## Adding a Gmail service

When you create a **Gmail** service, instead of typing config:

1. **Name the service** and pick an **OAuth client** — either one you've already added, or choose **Create a new client…** and paste your Google OAuth app's `Client ID` and `Client secret` (application type **Web application**).
2. If adding a new client, register the shown **OAuth Redirect URL** in that client's *Authorized redirect URIs* in the Google console.
3. **Continue to sign in** — complete Google's consent screen. The service is created and connected in one step; a cancelled/failed sign-in creates nothing.

Once connected, the service's page shows its grant and lets you reconnect or change clients.

## Prerequisites

- A [Google Cloud](https://console.cloud.google.com) project with the **Gmail API** enabled.
- An OAuth client of type **Web application**, created under **APIs & Services → Credentials → Create credentials → OAuth client ID**, with its **Authorized redirect URIs** set to this Presa instance's OAuth callback URL.
- The account you authorize must have access to that Gmail inbox.

## Notes

- Tokens (client secret, access token, refresh token) are stored encrypted.
- When the access token expires, Presa refreshes it automatically using the grant's refresh token. If a refresh/access fails (e.g. the grant is revoked), reconnect the service from its page.
- Each service holds its *own* client credential and grant; different services can use the same or different Google clients.