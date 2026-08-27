# Strava

Pull your Strava activity and profile data into a workspace. Add a Strava **OAuth client** and authorize your account, and Presa exposes tools for your athlete profile, your recent activities, individual activity detail, and your activity statistics as callable workspace tools. Built against [Strava's REST API reference](https://developers.strava.com/docs/reference/).

## Configuration

This kind is an **OAuth service** — you don't type API keys. Instead:

1. Register an app at the [Strava developer portal](https://developers.strava.com/) (your personal API application) and note its **Client ID** and **Client Secret**.
2. In Strava, set your app's **Authorization Callback Domain** to the Presa-host domain (the host of this Presa install).
3. In Presa: **Credentials → Add credential**, choose provider **strava**, give it a name, and paste the Client ID and Client Secret.
4. Add a **Strava** service and, when prompted to connect, pick that credential and approve the OAuth consent.

The service is connected once it has acquired a grant, and exposes its tools from then on. Tokens are acquired and refreshed automatically.

## Prerequisites

- A Strava developer app with a client ID and secret.
- A Strava account to authorize.

## Scope

Requests are made with `activity:read_all,profile:read_all` scope, so both your athlete profile/stats and your full activity feed (including private activities) are readable.

## Notes

- Connectivity is the acquired OAuth grant: a service is "connected" once it has one, and tokens refresh on demand.
- Redirect callback is preconfigured; only your client credentials are required.