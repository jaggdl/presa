# frozen_string_literal: true

require "test_helper"

class Services::NotionTest < ActiveSupport::TestCase
  test "is an offerable Notion OAuth leaf" do
    assert_equal "notion", Services::Notion.kind
    assert_includes Service.kinds, "notion"
    assert_equal "notion", Services::Notion.oauth_provider.to_s
    assert_equal Oauth::Notion, Services::Notion.provider_class
    assert_equal "https://api.notion.com/v1/oauth/authorize", Services::Notion.new.authorize_uri
    assert_equal "https://api.notion.com/v1/oauth/token", Services::Notion.new.token_uri
    assert_nil Services::Notion.oauth_scope
assert_equal "https://api.notion.com/v1", Services::Notion.oauth_api_base_url
    assert_equal({ "Notion-Version" => "2022-06-28" }, Services::Notion.oauth_api_headers)
    assert_equal :basic, Services::Notion.oauth_client_auth
    assert_empty Services::Notion.config_fields
  end

  test "composes a client against the API base URL carrying the API version pin" do
    service = services(:notion)
    client = service.client

    assert_instance_of Oauth::Client, client
  end

  test "is categorized as productivity" do
    assert_equal "productivity", Services::Notion.category
    assert Services::Notion.new(name: "Notion").productivity?
  end

  test "is valid as an OAuth service and reports connected with a grant" do
    assert services(:notion).valid?
    assert services(:notion).connected?
  end

  test "authorized_token returns the non-expiring token from its grant without refreshing" do
    service = services(:notion)
    assert_nil service.oauth_grant.expires_at
    assert_not service.oauth_grant.expired?

    assert_equal "notion_access", service.authorized_token
  end

  test "builds a Notion-specific authorize url (no scope, workspace owner)" do
    service = services(:notion)
    url = service.authorize_url(redirect_uri: "https://presa.example/oauth/callback", state: "abc123")

    assert_includes url, "https://api.notion.com/v1/oauth/authorize"
    assert_includes url, "client_id=notion_client_1"
    assert_includes url, "response_type=code"
    assert_includes url, "owner=workspace"
    assert_includes url, "redirect_uri=https%3A%2F%2Fpresa.example%2Foauth%2Fcallback"
    assert_includes url, "state=abc123"
    refute_includes url, "scope="
  end

  test "exposes the notion toolset" do
    kinds = ApplicationTool.expose_for(services(:notion)).map(&:kind)
    expected = %w[
      search get_page create_page get_database query_database
      get_block_children append_block_children
    ]
    expected.each { |kind| assert_includes kinds, kind }
  end
end
