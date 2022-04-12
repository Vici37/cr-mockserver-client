require "./spec_helper"

describe MockServerClient do
  client = MockServerClient::Client.new(port: 1090)
  regular_client = HTTP::Client.new("localhost", 1090)

  it "query params supported" do
    client.expectation(
      http_request: client.request(path: "/test1/test2", method: "GET", query_string_parameters: {"var" => ["foo|bar"]}),
      http_response: client.response(body: "success!")
    )

    resp = regular_client.get("/test1/test2")
    resp.status_code.should eq 404

    resp = regular_client.get("/test1/test2?var=foo")
    resp.status_code.should eq 200
    resp.body.should eq "success!"

    resp = regular_client.get("/test1/test2?var=bar")
    resp.status_code.should eq 200

    resp = regular_client.get("/test1/test2?var=baz")
    resp.status_code.should eq 404
  end

  it "header matchers supported" do
    client.expectation(
      http_request: client.request(headers: {"X-TEST" => ["totes"]}),
      http_response: client.response(status_code: 200)
    )

    resp = regular_client.get("/", HTTP::Headers{"X-TEST" => ["totes"]})
    resp.status_code.should eq 200

    resp = regular_client.get("/", nil)
    resp.status_code.should eq 404
  end

  it "path parameters supported" do
  end

  it "serializes all request body matcher types" do
    client.expectation(http_response: client.response(status_code: 200, body: "response1"))
    client.expectation(http_response: client.response(status_code: 200, body: JSON.parse({response: "one"}.to_json)))
    client.expectation(http_response: client.response(status_code: 200, body: MockServerClient::JsonPathBodyMatcher.new("$.store.book[?(@.price < 10)]")))
    client.expectation(http_response: client.response(status_code: 200, body: MockServerClient::BinaryBodyMatcher.new("ZnVjawo=")))
    client.expectation(http_response: client.response(status_code: 200, body: MockServerClient::ParametersBodyMatcher.new({"one" => ["two"]})))
    client.expectation(http_response: client.response(status_code: 200, body: MockServerClient::RegexBodyMatcher.new(".*")))
    client.expectation(http_response: client.response(status_code: 200, body: MockServerClient::StringBodyMatcher.new("totes")))
    client.expectation(http_response: client.response(status_code: 200, body: MockServerClient::XpathBodyMatcher.new("//")))
    client.expectation(http_response: client.response(status_code: 200, body: MockServerClient::XmlBodyMatcher.new("<totes></totes>")))
    client.expectation(http_response: client.response(status_code: 200, body: MockServerClient::JsonBodyMatcher.new(JSON.parse("{}"))))

    exps = client.retrieve(type: "active_expectations")
    exps.size.should eq 10
  end

  it "serializes all response body types" do
    client.expectation(http_response: client.response(body: "response1"))
    client.expectation(http_response: client.response(body: JSON.parse({response: "one"}.to_json)))
    client.expectation(http_response: client.response(body: MockServerClient::BinaryBodyMatcher.new("ZnVjawo=")))
    client.expectation(http_response: client.response(body: MockServerClient::StringBodyMatcher.new("totes")))
    client.expectation(http_response: client.response(body: MockServerClient::XmlBodyMatcher.new("<totes></totes>")))
    client.expectation(http_response: client.response(body: MockServerClient::JsonBodyMatcher.new(JSON.parse("{}"))))

    exps = client.retrieve(type: "active_expectations")
    exps.size.should eq 6
  end
end
