# frozen_string_literal: true

require "test_helper"

class SeerrServiceTest < ActiveSupport::TestCase
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
    service = Services::Seerr.new(user: users(:one), name: "Test", config: { "api_key" => "abc", "base_url" => "http://localhost:5055" })
    service.instance_variable_set(:@conn, fake_conn)
    service
  end

  test "get sends the api key header and prefixes the api version" do
    fake = FakeConn.new({ "version" => "1.0" })
    build_service(fake).get("/status")

    assert_equal "get", fake.method
    assert_includes fake.called, "/api/v1/status"
    assert_equal "abc", fake.headers["X-Api-Key"]
  end

  test "post sends JSON body and api key header" do
    fake = FakeConn.new(nil)
    build_service(fake).post("/request", body: { title: "Dune" })

    assert_equal "post", fake.method
    assert_equal "/api/v1/request", fake.called.first
    assert_equal({ "title" => "Dune" }, JSON.parse(fake.body))
    assert_equal "abc", fake.headers["X-Api-Key"]
  end
end