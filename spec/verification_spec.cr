require "./spec_helper"

describe MockServerClient do
  client = MockServerClient::Client.new(port: 1090)
  regular_client = HTTP::Client.new("localhost", 1090)

  it "verifies expectation" do
    exp = client.expectation(
      http_request: client.request(path: "/hello/world", method: "POST"),
      http_response: client.response(body: "success!")
    )[0]

    client.verify(exp, at_least: 1).should be_false
    regular_client.post("/hello/world").body.should eq "success!"
    client.verify(exp, at_least: 1, at_most: 1).should be_true
    regular_client.post("/hello/world").body.should eq "success!"
    client.verify(exp, at_most: 1).should be_false
    client.verify(MockServerClient::HttpRequest.new(path: "/hello/world", method: "POST"), at_least: 2).should be_true
  end

  it "verifies sequences" do
    exp1 = client.expectation(
      http_request: client.request(path: "/hello/world", method: "POST"),
      http_response: client.response(body: "success!")
    )[0]
    exp2 = client.expectation(
      http_request: client.request(path: "/goodbye/world", method: "POST"),
      http_response: client.response(body: "success!")
    )[0]
    exp3 = client.expectation(
      http_request: client.request(path: "/world", method: "POST"),
      http_response: client.response(body: "success!")
    )[0]

    client.verify_sequence([exp1, exp2, exp3]).should be_false
    regular_client.post("/hello/world")
    client.verify_sequence([exp1, exp2, exp3]).should be_false
    regular_client.post("/goodbye/world")
    client.verify_sequence([exp1, exp2, exp3]).should be_false
    regular_client.post("/world")
    client.verify_sequence([exp1, exp2, exp3]).should be_true

    client.verify_sequence([
      client.request(path: "/hello/world"),
      client.request(path: "/goodbye/world"),
      client.request(path: "/world"),
    ]).should be_true

    client.verify_sequence([
      client.request(path: "/goodbye/world"),
      client.request(path: "/hello/world"),
      client.request(path: "/world"),
    ]).should be_false
  end
end
