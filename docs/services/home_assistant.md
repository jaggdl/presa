# Home Assistant

Control your Home Assistant instance from a workspace. Add the **Model Context Protocol Server** integration to Home Assistant, upload a long-lived access token here, and Presa exposes Home Assistant's Assist tools (turn lights on/off, query the state of switches and sensors, manage to-do lists, and more) as callable workspace tools. Only entities you've exposed to the Assist API are reachable.

## Configuration

This service kind accepts the following configuration fields:

| field | required | secret | default | what it does |
| --- | --- | --- | --- | --- |
| `base_url` | yes | no | — | The URL of your Home Assistant instance, e.g. `http://homeassistant.local:8123`. The MCP endpoint is resolved as `<base_url>/api/mcp`. |
| `access_token` | yes | yes | — | A Home Assistant **Long-Lived Access Token** used to authenticate. Create one under **user icon → Security** on your instance. Requests are authenticated by sending it in the `Authorization: Bearer <access_token>` header. |

The endpoint path (`/api/mcp`) and the `Authorization: Bearer` header are preconfigured; you only supply the instance URL and the token.

## Prerequisites

Before this service surfaces any tools, your Home Assistant needs the MCP Server integration enabled:

1. On your Home Assistant instance, go to **Settings → Devices & services → Add Integration** and select **Model Context Protocol Server**.
2. Follow the on-screen setup. Enabled MCP clients are allowed to control Home Assistant.
3. Create a **Long-Lived Access Token**: go to your **user profile → Security** page → **Long-Lived Access Tokens → Create Token**, and copy the token it shows.
4. Decide whether to expose control of specific entities, and ensure the entities you want to drive are exposed to the Assist API.

## Notes

- The integration uses the built-in **Assist API**, so `base_url` maps to `GET <base_url>/api/mcp`. You only need `base_url` and `access_token`; path and auth header are preconfigured.
- Non-Administrator tokens can still drive the Assist API; administrator privileges are only required to reach a specific LLM API by ID.