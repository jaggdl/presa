# frozen_string_literal: true

require "test_helper"

class JellyfinServiceTest < ActiveSupport::TestCase
  class Response
    attr_reader :body

    def initialize(body)
      @body = body
    end
  end

  class FakeReq
    attr_accessor :headers, :body

    def initialize
      @headers = {}
    end
  end

  class FakeConn
    attr_reader :called, :method, :body, :headers

    def initialize(response_body)
      @response_body = response_body
      @called = []
    end

    def get(path, &block)
      @method = "get"; @called << path
      req = build_req(&block)
      @headers = req.headers
      Response.new(@response_body)
    end

    def delete(path, &block)
      @method = "delete"; @called << path
      req = build_req(&block)
      @headers = req.headers
      Response.new(nil)
    end

    def post(path, &block)
      @method = "post"; @called << path
      req = FakeReq.new
      block.call(req)
      @body = req.body
      @headers = req.headers
      Response.new(nil)
    end

    private

    def build_req(&block)
      req = FakeReq.new
      block.call(req) if block
      req
    end
  end

  def build_service(fake_conn)
    service = Services::Jellyfin.new(user: users(:one), name: "Test", config: { "api_key" => "abc", "base_url" => "http://jf" })
    service.instance_variable_set(:@conn, fake_conn)
    service
  end

  test "post sends JSON body and api key header" do
    fake = FakeConn.new(nil)
    build_service(fake).post("/Items/1", body: { key: "value" })

    assert_equal "post", fake.method
    assert_equal({ "key" => "value" }, JSON.parse(fake.body))
    assert_equal "abc", fake.headers["X-Emby-Token"]
  end

  test "delete sends api key header" do
    fake = FakeConn.new(nil)
    build_service(fake).delete("/UserFavoriteItems/1")

    assert_equal "delete", fake.method
    assert_includes fake.called, "/UserFavoriteItems/1"
    assert_equal "abc", fake.headers["X-Emby-Token"]
  end
end
