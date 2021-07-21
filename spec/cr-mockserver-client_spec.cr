require "./spec_helper"

describe MockServerClient do
  client = MockServerClient::Client.new(port: 1090)
  regular_client = HTTP::Client.new("localhost", 1090)

  it "creates and retrieves expectations" do
    resp = client.expectation(
      path: "/hello/world",
      method: "GET",
      responseBody: "world!"
    )

    resp.size.should eq 1
    resp[0].id.should_not be_nil
    resp[0].httpRequest.path.should eq "/hello/world"

    exps = client.retrieve("active_expectations")
    exps.size.should eq 1
    exps[0].should eq resp[0]

    resp = regular_client.get("/hello/world")
    resp.status_code.should eq 200
    resp.body.should eq "world!"

    client.reset
    exps = client.retrieve("active_expectations")
    exps.size.should eq 0
  end

  it "checks port bindings and binds to new ones" do
    stats = client.status
    stats.ports.should eq [1080]

    stats = client.bind(1081)
    stats.ports.should eq [1080, 1081]
  end

  it "gets requests" do
    resp = regular_client.get("/does/not/exist")
    resp.status_code.should eq 404

    requests = client.retrieve("requests").as(Array(MockServerClient::HttpRequest))
    requests.size.should eq 1
    req = requests[0]
    req.path.should eq "/does/not/exist"
    req.method.should eq "GET"
  end

  it "retrieves logs, recorded_expectations, and request_responses" do
    regular_client.get("/")
    client.expectation(path: "/nope")
    regular_client.get("/nope")
    req_resps = client.retrieve("request_responses").as(Array(MockServerClient::RequestResponse))

    req_resps.size.should eq 2
    req_resps[0].httpRequest.path.should eq "/"
    req_resps[0].httpResponse.statusCode.should eq 404

    req_resps[1].httpRequest.path.should eq "/nope"
    req_resps[1].httpResponse.statusCode.should eq 200

    client.retrieve("recorded_expectations").should be_empty # no proxy expectations

    client.retrieve("logs").empty?.should be_false
  end
end
