require "./spec_helper"

describe MockServerClient do
  client = MockServerClient::Client.new(port: 1090)
  regular_client = HTTP::Client.new("localhost", 1090)

  it "query params supported" do
    client.expectation(
      path: "/test1/test2",
      method: "GET",
      requestQueryParams: {"var" => ["foo|bar"]},
      responseBody: "success!"
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
    client.expectation(responseStatusCode: 200, requestHeaders: {"X-TEST" => ["totes"]})

    resp = regular_client.get("/", HTTP::Headers{"X-TEST" => ["totes"]})
    resp.status_code.should eq 200

    resp = regular_client.get("/", nil)
    resp.status_code.should eq 404
  end

  it "path parameters supported" do
  end

  it "serializes all request body matcher types" do
    client.expectation(responseStatusCode: 200, requestBody: "response1")
    client.expectation(responseStatusCode: 200, requestBody: JSON.parse({response: "one"}.to_json))
    client.expectation(responseStatusCode: 200, requestBody: MockServerClient::JsonPathBodyMatcher.new("$.store.book[?(@.price < 10)]"))
    client.expectation(responseStatusCode: 200, requestBody: MockServerClient::BinaryBodyMatcher.new("ZnVjawo="))
    client.expectation(responseStatusCode: 200, requestBody: MockServerClient::ParametersBodyMatcher.new({"one" => ["two"]}))
    client.expectation(responseStatusCode: 200, requestBody: MockServerClient::RegexBodyMatcher.new(".*"))
    client.expectation(responseStatusCode: 200, requestBody: MockServerClient::StringBodyMatcher.new("totes"))
    client.expectation(responseStatusCode: 200, requestBody: MockServerClient::XpathBodyMatcher.new("//"))
    client.expectation(responseStatusCode: 200, requestBody: MockServerClient::XmlBodyMatcher.new("<totes></totes>"))
    client.expectation(responseStatusCode: 200, requestBody: MockServerClient::JsonBodyMatcher.new(JSON.parse("{}")))

    exps = client.retrieve(type: "active_expectations")
    exps.size.should eq 10
  end

  it "serializes all response body types" do
    client.expectation(responseBody: "response1")
    client.expectation(responseBody: JSON.parse({response: "one"}.to_json))
    client.expectation(responseBody: MockServerClient::BinaryBodyMatcher.new("ZnVjawo="))
    client.expectation(responseBody: MockServerClient::StringBodyMatcher.new("totes"))
    client.expectation(responseBody: MockServerClient::XmlBodyMatcher.new("<totes></totes>"))
    client.expectation(responseBody: MockServerClient::JsonBodyMatcher.new(JSON.parse("{}")))

    exps = client.retrieve(type: "active_expectations")
    exps.size.should eq 6
  end
end
