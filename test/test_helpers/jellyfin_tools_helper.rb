# frozen_string_literal: true

# Shared support for testing Jellyfin tools. Each tool test file in
# `test/tools/jellyfin/` includes this module to get a small fake service that
# records the requested path (so we assert the API endpoint + query params
# without any network access) and a helper to build a bound tool instance.
module JellyfinToolTestHelper
  # Captures the path passed to `get` so tests can assert the endpoint.
  class FakeService
    # Responds to the `/Users` lookup used by `resolve_user_id` so the bound
    # tool always resolves a concrete user id in tests. Override via `users:`.
    attr_reader :paths

    def initialize(users: nil)
      @paths = []
      @users = users || [ { "Id" => "user-1" } ]
    end

    def get(path)
      @paths << path
      return @users if path.to_s == "/Users"

      nil
    end

    # The path from the last `get` call — the tool's actual media request (not
    # the user-resolution lookup made earlier by `resolve_user_id`).
    def last_path
      @paths.last
    end
  end

  # Builds the bound tool class for `kind` against the `jellyfin` fixture and
  # swaps in a fake service so `call` records paths instead of hitting the
  # network. Returns `[tool, fake]`.
  def expose_jellyfin_tool(kind)
    fake = FakeService.new
    klass = ApplicationTool.expose_for(services(:jellyfin)).find { |t| t.kind == kind }
    tool = klass.new
    tool.instance_variable_set(:@service, fake)
    [ tool, fake ]
  end
end
