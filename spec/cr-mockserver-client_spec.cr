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

    exps = client.retrieve(type: "active_expectations")
    exps.size.should eq 1
    exps[0].should eq resp[0]

    resp = regular_client.get("/hello/world")
    resp.status_code.should eq 200
    resp.body.should eq "world!"

    client.reset
    exps = client.retrieve(type: "active_expectations")
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

    requests = client.retrieve(type: "requests").as(Array(MockServerClient::HttpRequest))
    requests.size.should eq 1
    req = requests[0]
    req.path.should eq "/does/not/exist"
    req.method.should eq "GET"
  end
end
