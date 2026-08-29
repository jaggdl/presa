# frozen_string_literal: true

require "test_helper"

class Services::GoogleAnalyticsTest < ActiveSupport::TestCase
  test "is an offerable GoogleAnalytics OAuth leaf" do
    assert_equal "google_analytics", Services::GoogleAnalytics.kind
    assert_includes Service.kinds, "google_analytics"
    assert_equal "google", Services::GoogleAnalytics.oauth_provider.to_s
    assert_equal Oauth::Google, Services::GoogleAnalytics.provider_class
    assert_equal "https://accounts.google.com/o/oauth2/v2/auth", Services::GoogleAnalytics.new.authorize_uri
    assert_equal "https://oauth2.googleapis.com/token", Services::GoogleAnalytics.new.token_uri
    assert_equal "https://www.googleapis.com/auth/analytics.readonly", Services::GoogleAnalytics.oauth_scope
    assert_empty Services::GoogleAnalytics.config_fields
  end

  test "is categorized as productivity" do
    assert_equal "productivity", Services::GoogleAnalytics.category
    assert Services::GoogleAnalytics.new(name: "GA").productivity?
  end

  test "is valid as an OAuth service and reports connected with a grant" do
    assert services(:google_analytics).valid?
    assert services(:google_analytics).connected?
  end

  test "exposes the provider name" do
    assert_equal "google", services(:google_analytics).provider
  end

  test "authorized_token returns the valid access token from its grant" do
    assert_equal "fresh_access", services(:google_analytics).authorized_token
  end

  test "exposes the analytics toolset" do
    kinds = ApplicationTool.expose_for(services(:google_analytics)).map(&:kind)
    expected = %w[
      get_account_summaries get_property_details list_google_ads_links list_property_annotations
      run_report run_realtime_report run_funnel_report run_conversions_report
      get_custom_dimensions_and_metrics
    ]
    expected.each { |kind| assert_includes kinds, kind }
  end

  test "composes a client per API base URL" do
    service = services(:google_analytics)
    assert_instance_of Oauth::Client, service.client(base_url: GoogleAnalytics::Base::ADMIN_API)
    assert_instance_of Oauth::Client, service.client(base_url: GoogleAnalytics::Base::DATA_API)
  end

  test "memoizes one client per API base URL" do
    service = services(:google_analytics)
    assert_same service.client(base_url: GoogleAnalytics::Base::DATA_API), service.client(base_url: GoogleAnalytics::Base::DATA_API)
    assert_not_same service.client(base_url: GoogleAnalytics::Base::ADMIN_API), service.client(base_url: GoogleAnalytics::Base::DATA_API)
  end
end
