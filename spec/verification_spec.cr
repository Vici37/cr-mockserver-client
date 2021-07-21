require "./spec_helper"

describe MockServerClient do
  client = MockServerClient::Client.new(port: 1090)
  regular_client = HTTP::Client.new("localhost", 1090)

  it "verifies expectation" do
    exp = client.expectation(
      path: "/hello/world",
      method: "POST",
      responseBody: "success!"
    )[0]

    client.verify(exp, atLeast: 1).should be_false
    regular_client.post("/hello/world").body.should eq "success!"
    client.verify(exp, atLeast: 1, atMost: 1).should be_true
    regular_client.post("/hello/world").body.should eq "success!"
    client.verify(exp, atMost: 1).should be_false
    client.verify(MockServerClient::HttpRequest.new(path: "/hello/world", method: "POST"), atLeast: 2).should be_true
  end

  it "verifies sequences" do
    exp1 = client.expectation(
      path: "/hello/world",
      method: "POST",
      responseBody: "success!"
    )[0]
    exp2 = client.expectation(
      path: "/goodbye/world",
      method: "POST",
      responseBody: "success!"
    )[0]
    exp3 = client.expectation(
      path: "/world",
      method: "POST",
      responseBody: "success!"
    )[0]
    regular_client.post("/hello/world")
    regular_client.post("/goodbye/world")
    regular_client.post("/world")

    client.verify_sequence([
      MockServerClient::HttpRequest.new(path: "/hello/world"),
      MockServerClient::HttpRequest.new(path: "/goodbye/world"),
      MockServerClient::HttpRequest.new(path: "/world"),
    ]).should be_true

    client.verify_sequence([
      MockServerClient::HttpRequest.new(path: "/goodbye/world"),
      MockServerClient::HttpRequest.new(path: "/hello/world"),
      MockServerClient::HttpRequest.new(path: "/world"),
    ]).should be_false
  end
end
