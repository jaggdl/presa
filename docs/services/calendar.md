# Google Calendar

Read and manage a Google Calendar account from a workspace (list, create, update, and delete events) using Google OAuth2.

Like Gmail, this service uses **bring-your-own OAuth**: you register a Google OAuth client and authorize a Google account that owns the calendars you want to manage. The scope requested is the full Calendar scope, so the workspace can read and edit events across the authorized account's calendars. You only authorize once per service; Presa stores the tokens and refreshes them for you.

## Adding a Google Calendar service

When you create a **Google Calendar** service, instead of typing config:

1. **Name the service** and pick an **OAuth client** — either one you've already added, or choose **Create a new client…** and paste your Google OAuth app's `Client ID` and `Client secret` (application type **Web application**).
2. If adding a new client, register the shown **OAuth Redirect URL** in that client's *Authorized redirect URIs* in the Google console.
3. **Continue to sign in** — complete Google's consent screen. The service is created and connected in one step; a cancelled/failed sign-in creates nothing.

Once connected, the service's page shows its grant and lets you reconnect or change clients.

## Prerequisites

- A [Google Cloud](https://console.cloud.google.com) project with the **Google Calendar API** enabled.
- An OAuth client of type **Web application**, created under **APIs & Services → Credentials → Create credentials → OAuth client ID**, with its **Authorized redirect URIs** set to this Presa instance's OAuth callback URL.
- The account you authorize must own (or have access to) the calendars you want to manage.

## Notes

- Tokens (client secret, access token, refresh token) are stored encrypted.
- When the access token expires, Presa refreshes it automatically using the grant's refresh token. If a refresh/access fails (e.g. the grant is revoked), reconnect the service from its page.
- Each service holds its *own* client credential and grant; different services can use the same or different Google clients.
- Tools accept a `calendar_id`; with no calendar given they operate on the account's **primary** calendar. Message-like tools accept times in RFC3339 format (e.g. `2026-09-01T10:00:00-04:00`) for timed events, or a bare `YYYY-MM-DD` date for all-day events.