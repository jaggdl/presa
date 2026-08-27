# GitHub

Access your GitHub account to read issues, pull requests, and repository activity directly from a workspace. Works against **GitHub.com** or a self-hosted [GitHub Enterprise Server](https://docs.github.com/enterprise-server).

## Configuration

This service kind accepts the following configuration fields:

| field | required | secret | default | what it does |
| --- | --- | --- | --- | --- |
| `api_token` | yes | yes | — | GitHub Personal Access Token (PAT). Create one at GitHub → Settings → Developer settings → Personal access tokens. Give it the scopes the tools need — e.g. `repo` to read issues/PRs on private repositories, or `public_repo` for public ones. Requests are authenticated via this token. |
| `base_url` | no | no | `https://api.github.com` | The API base URL. Leave the default for GitHub.com. For a self-hosted GitHub Enterprise Server, set it to `https://<your-enterprise-host>/api/v3`. |