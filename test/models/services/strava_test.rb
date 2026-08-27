# frozen_string_literal: true

require "test_helper"

class StravaServiceTest < ActiveSupport::TestCase
  test "kind is strava" do
    assert_equal "strava", Services::Strava.kind
  end

  test "config_fields are declared" do
    fields = Services::Strava.config_fields
    assert fields.key?(:client_id)
    assert fields.key?(:client_secret)
    assert fields.key?(:refresh_token)
  end

  test "client_id is required" do
    assert Services::Strava.config_fields[:client_id][:required]
  end

  test "client_secret is required and secret" do
    field = Services::Strava.config_fields[:client_secret]
    assert field[:required]
    assert field[:secret]
  end

  test "refresh_token is required and secret" do
    field = Services::Strava.config_fields[:refresh_token]
    assert field[:required]
    assert field[:secret]
  end

  test "validates required fields on create" do
    service = Services::Strava.new(user: users(:one), name: "Test Strava")
    assert_not service.valid?
    assert_includes service.errors.details[:config].map { |e| e[:error] }, :client_id
  end

  test "does not raise on valid config" do
    service = Services::Strava.new(
      user: users(:one),
      name: "Test Strava",
      config: { client_id: "123", client_secret: "secret", refresh_token: "refresh" }
    )
    assert service.valid?
  end
end