# frozen_string_literal: true

# Shared support for testing GitHub tools. Each tool test file in
# `test/tools/github/` includes this module. See `JellyfinToolTestHelper` for
# the same pattern applied to the Jellyfin family.
module GithubToolTestHelper
  class FakeService
    attr_reader :paths

    def initialize
      @paths = []
    end

    def get(path)
      @paths << path
    end

    def last_path
      @paths.last
    end
  end

  def expose_github_tool(kind)
    fake = FakeService.new
    klass = ApplicationTool.expose_for(services(:github_prod)).find { |t| t.kind == kind }
    tool = klass.new
    tool.instance_variable_set(:@service, fake)
    [ tool, fake ]
  end
end
