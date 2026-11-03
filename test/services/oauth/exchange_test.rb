require "test_helper"

class Oauth::ExchangeTest < ActiveSupport::TestCase
  test "builds a well-formed authorize url" do
    url = Oauth::Exchange.new.authorize_url(
      uri: "https://accounts.google.com/o/oauth2/v2/auth",
      client_id: "cid",
      redirect_uri: "https://presa.example/oauth/callback",
      scope: "gmail.send",
      state: "abc"
    )
    assert_includes url, "https://accounts.google.com/o/oauth2/v2/auth"
    params = Rack::Utils.parse_nested_query(URI(url).query)
    assert_equal "code", params["response_type"]
    assert_equal "cid", params["client_id"]
    assert_equal "abc", params["state"]
    assert_equal "gmail.send", params["scope"]
  end

  def stub_exchange(&blk)
    conn = Faraday.new("https://oauth2.googleapis.com/token") { |f| f.adapter :test, &blk }
    Oauth::Exchange.new(connection: conn)
  end

  test "exchange_code posts to the token endpoint and parses the response" do
    exchange = stub_exchange do |stub|
      stub.post("/token") do |_env|
        [ 200, { "content-type" => "application/json" }, JSON.generate(
          "access_token" => "acc", "refresh_token" => "ref", "token_type" => "Bearer", "expires_in" => 3600
        ) ]
      end
    end

    tokens = exchange.exchange_code(
      token_uri: "https://oauth2.googleapis.com/token",
      code: "code123",
      client_id: "cid",
      client_secret: "secret",
      redirect_uri: "https://presa.example/oauth/callback"
    )
    assert_equal "acc", tokens["access_token"]
    assert_equal "ref", tokens["refresh_token"]
    assert_equal 3600, tokens["expires_in"]
  end

  test "refresh posts grant_type=refresh_token and returns a fresh access token" do
    exchange = stub_exchange do |stub|
      stub.post("/token") do |env|
        assert_includes env.body, "grant_type=refresh_token"
        assert_includes env.body, "refresh_token=old"
        [ 200, { "content-type" => "application/json" }, JSON.generate("access_token" => "new_acc", "expires_in" => 3600) ]
      end
    end

    tokens = exchange.refresh(
      token_uri: "https://oauth2.googleapis.com/token",
      refresh_token: "old",
      client_id: "cid",
      client_secret: "secret"
    )
    assert_equal "new_acc", tokens["access_token"]
  end

  test "exchange_code with basic auth sends JSON and a Basic Authorization header (Notion)" do
    exchange = stub_exchange do |stub|
      stub.post("/token") do |env|
        assert_equal "Basic #{Base64.strict_encode64("cid:secret")}", env.request_headers["Authorization"]
        assert_equal "application/json", env.request_headers["Content-Type"]
        body = JSON.parse(env.body)
        assert_equal "authorization_code", body["grant_type"]
        assert_equal "code123", body["code"]
        assert_equal "https://presa.example/oauth/callback", body["redirect_uri"]
        assert_nil body["client_id"]
        assert_nil body["client_secret"]
        [ 200, { "content-type" => "application/json" }, JSON.generate("access_token" => "acc") ]
      end
    end

    tokens = exchange.exchange_code(
      token_uri: "https://oauth2.googleapis.com/token",
      code: "code123",
      client_id: "cid",
      client_secret: "secret",
      redirect_uri: "https://presa.example/oauth/callback",
      client_auth: :basic
    )
    assert_equal "acc", tokens["access_token"]
  end

  test "raises on a non-success token response" do
    exchange = stub_exchange do |stub|
      stub.post("/token") do |_env|
        [ 400, { "content-type" => "application/json" }, JSON.generate("error" => "invalid_grant") ]
      end
    end

    assert_raises(Oauth::Error) do
      exchange.refresh(token_uri: "https://oauth2.googleapis.com/token", refresh_token: "r", client_id: "c", client_secret: "s")
    end
  end

  test "a rejected refresh token raises ReconnectRequired, not a raw provider error" do
    exchange = stub_exchange do |stub|
      stub.post("/token") do |_env|
        [ 400, { "content-type" => "application/json" },
          JSON.generate("error" => "invalid_grant", "error_description" => "Token has been expired or revoked.") ]
      end
    end

    error = assert_raises(Oauth::ReconnectRequired) do
      exchange.refresh(token_uri: "https://oauth2.googleapis.com/token", refresh_token: "r", client_id: "c", client_secret: "s")
    end

    assert_includes error.message, "expired or been revoked"
    assert_not_includes error.message, "invalid_grant"
    assert_not_includes error.message, "Token has been expired or revoked"
  end

  test "a rejected authorization code stays a generic Oauth::Error (not a reconnect)" do
    exchange = stub_exchange do |stub|
      stub.post("/token") do |_env|
        [ 400, { "content-type" => "application/json" }, JSON.generate("error" => "invalid_grant") ]
      end
    end

    assert_raises(Oauth::Error) do
      exchange.exchange_code(
        token_uri: "https://oauth2.googleapis.com/token",
        code: "expired", client_id: "c", client_secret: "s", redirect_uri: "https://presa.example/oauth/callback"
      )
    end
  end
end
