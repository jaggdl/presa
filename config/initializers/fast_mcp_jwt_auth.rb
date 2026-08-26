# frozen_string_literal: true

# Authenticate MCP requests via opaque bearer tokens instead of JWTs.
# Tokens are issued per workspace and stored as a SHA-256 digest in api_tokens.
# A token resolves to its owning workspace, which identifies the principal
# (Current.workspace) and its owner (Current.user). See app/models/api_token.rb.

FastMcpJwtAuth.configure do |config|
  config.enabled = true

  # Resolve the raw bearer token to an active ApiToken record (or nil).
  config.jwt_decoder = ->(raw_token) { ApiToken.find_active_by_token(raw_token) }

  # The decoder already verifies the token is active; just confirm it exists.
  config.token_validator = ->(token) { token.present? }

  # The principal is the token's owning workspace, not the user directly.
  config.user_finder = ->(token) do
    Current.api_token = token
    token.workspace
  end

  # Set the current workspace; keep Current.user via the existing session pattern.
  config.current_user_setter = ->(workspace) do
    Current.workspace = workspace
    Current.session = Session.new(user: workspace.user)
  end

  # Reset current context after the request.
  config.current_resetter = -> { Current.reset }
end
