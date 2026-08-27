ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require_relative "test_helpers/jellyfin_tools_helper"
require_relative "test_helpers/gmail_tools_helper"
require_relative "test_helpers/strava_tools_helper"
require_relative "test_helpers/spotify_tools_helper"
require_relative "test_helpers/places_tools_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Preset MCP kinds (e.g. Services::Github) discover their tools from a
    # remote endpoint. Stub discovery to a canned list so exposing them in
    # tests never hits the network. Generic Services::Mcp instances set their
    # own fake client in the dedicated tests below, so they are unaffected.
    setup do
      Services::Github.class_eval do
        def remote_tools
          [
            { "name" => "web_search", "description" => "Search the web",
              "inputSchema" => { "type" => "object", "properties" => { "q" => { "type" => "string" } }, "required" => [ "q" ] } }
          ]
        end
      end
    end

    # Reusable in-memory cache is shared across tests in a single process; clear
    # it between tests so cache-based throttles (e.g. bot token-redeem rate
    # limit) start from a clean slate every time.
    teardown { Rails.cache.clear }

    # Add more helper methods to be used by all tests here...
  end
end
