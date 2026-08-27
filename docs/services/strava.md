# Strava

Access athlete activities, stats, segments, and more from the Strava v3 REST API.

## Configuration

| Field | Required | Description |
|-------|----------|-------------|
| Client ID | ✅ Yes | Your Strava application's client ID from https://www.strava.com/settings/api |
| Client Secret | ✅ Yes | Your Strava application's client secret |
| Refresh Token | ✅ Yes | A Strava refresh token with the desired scopes (`activity:read_all`, `read`, etc.) |

### How to get a refresh token

1. Go to [Strava API Settings](https://www.strava.com/settings/api) and note your **Client ID** and **Client Secret**.
2. Visit the following URL in a browser (replace `YOUR_CLIENT_ID`):
   ```
   https://www.strava.com/oauth/authorize?client_id=YOUR_CLIENT_ID&redirect_uri=http://localhost&response_type=code&approval_prompt=force&scope=read,activity:read_all,profile:read_all
   ```
3. Authorize the app. You'll be redirected to `http://localhost?state=&code=AUTHORIZATION_CODE`.
4. Exchange the authorization code for tokens:
   ```bash
   curl -X POST https://www.strava.com/oauth/token \
     -H "Content-Type: application/json" \
     -d '{"client_id":"YOUR_CLIENT_ID","client_secret":"YOUR_CLIENT_SECRET","code":"AUTHORIZATION_CODE","grant_type":"authorization_code"}'
   ```
5. From the response, copy the `refresh_token` value — it does not expire unless revoked.

Use the refresh token (not the short-lived access token) in the config. The service auto-refreshes the access token on every API call.