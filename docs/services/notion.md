# Notion

Search and read a Notion workspace from one of your workspaces (search pages and databases, read pages/databases and their blocks, create pages, query a database, append blocks) using Notion's own OAuth.

Like the other OAuth services, Notion is **bring-your-own OAuth**: you register a Notion integration and authorize the workspace you want the workspace to access. You only authorize once per service; the issued integration token is stored encrypted.

## Adding a Notion service

When you create a **Notion** service, instead of typing config:

1. **Name the service** and pick an **OAuth client** — either one you've already added, or choose **Create a new client…** and paste your Notion integration's `Client ID` and `Client secret`.
2. If adding a new client, register the shown **OAuth Redirect URL** in the integration's *Redirect URIs* in Notion.
3. **Continue to sign in** — Notion asks which workspace to let the integration into. The service is created and connected in one step; a cancelled/failed sign-in creates nothing.

Once connected, the service's page shows its grant and lets you reconnect or change clients. **Important:** reconnecting replaces the integration token; pages in other workspaces or previously-authorized workspaces are not accessible after that.

## Prerequisites

- A [Notion integration](https://www.notion.so/my-integrations) (any type) with its **Redirect URIs** set to this Presa instance's OAuth callback URL.
- The workspace(s) you authorize must be the ones whose pages you want the workspace to read/write.

## Notes

- Notion integration tokens **never expire** and do not rotate, so there is no refresh flow: the stored token is used as-is. If you revoke the integration in Notion, reconnect the service from its page.
- Every request sends the `Notion-Version` API pin (`2022-06-28`).
- IDs are flexible: pass a bare 32-hex ID, a dashed UUID, or a pasted `notion.so` link (the trailing token is extracted).
- Property values and block objects follow the Notion API schema exactly, so check `get_database` first to see a database's property schema when creating pages or querying rows.