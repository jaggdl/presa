# frozen_string_literal: true

require "net/http"

module Tools
  module Github
    # Lists issues for a repository using the GitHub service's config.
    class ListIssues < Base
      description "List issues for a repository"
      kind :list_issues

      arguments do
        required(:repo).filled(:string).description("Repository in owner/name format")
      end

      def call(repo:)
        service = Service.find(self.class.service_id)
        uri = URI("#{service.config[:base_url]}/repos/#{repo}/issues")

        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Bearer #{service.config[:api_token]}"
        request["Accept"] = "application/vnd.github+json"

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
        JSON.parse(response.body)
      rescue StandardError => e
        { error: e.message }
      end
    end
  end
end
