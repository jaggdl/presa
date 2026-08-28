# Google Analytics

Query your Google Analytics 4 properties from a workspace — account/property lookup and Data API reports — using Google OAuth2.

Like Gmail, this service uses **bring-your-own OAuth**: you register a Google OAuth client and authorize a Google account that has access to the GA4 properties you want to query. The scope requested is `analytics.readonly`. You only authorize once per service; Presa stores the tokens and refreshes them for you.

## Adding a Google Analytics service

When you create a **Google Analytics** service, instead of typing config:

1. **Name the service** and pick an **OAuth client** — either one you've already added, or choose **Create a new client…** and paste your Google OAuth app's `Client ID` and `Client secret` (application type **Web application**).
2. If adding a new client, register the shown **OAuth Redirect URL** in that client's *Authorized redirect URIs* in the Google console.
3. **Continue to sign in** — complete Google's consent screen. The service is created and connected in one step; a cancelled/failed sign-in creates nothing.

Once connected, the service's page shows its grant and lets you reconnect or change clients.

## Prerequisites

- A [Google Cloud](https://console.cloud.google.com) project with the **Google Analytics Admin API** and **Google Analytics Data API** enabled.
- An OAuth client of type **Web application**, created under **APIs & Services → Credentials → Create credentials → OAuth client ID**, with its **Authorized redirect URIs** set to this Presa instance's OAuth callback URL.
- The account you authorize must have access to the GA4 accounts/properties you want to read.

## Notes

- Tokens (client secret, access token, refresh token) are stored encrypted.
- When the access token expires, Presa refreshes it automatically using the grant's refresh token. If a refresh/access fails (e.g. the grant is revoked), reconnect the service from its page.
- Each service holds its *own* client credential and grant; different services can use the same or different Google clients.