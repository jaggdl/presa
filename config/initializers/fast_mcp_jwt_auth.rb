# frozen_string_literal: true

# Authenticate MCP requests via opaque bearer tokens instead of JWTs.
# Tokens are issued from the root page (ApiTokensController), stored as a
# SHA-256 digest in api_tokens, and resolved back to their owning user.
# See app/models/api_token.rb.

FastMcpJwtAuth.configure do |config|
  config.enabled = true

  # Resolve the raw bearer token to an active ApiToken record (or nil).
  config.jwt_decoder = ->(raw_token) { ApiToken.find_active_by_token(raw_token) }

  # The decoder already verifies the token is active; just confirm it exists.
  config.token_validator = ->(token) { token.present? }

  # Find the user that owns the token.
  config.user_finder = ->(token) { token.user }

  # This app scopes context to a session; set a virtual one so Current.user works.
  config.current_user_setter = ->(user) { Current.session = Session.new(user: user) }

  # Reset current context after the request.
  config.current_resetter = -> { Current.reset }
end
