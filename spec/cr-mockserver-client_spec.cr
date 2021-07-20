require "uuid"
require "./spec_helper"

describe MockServerClient do
  api = Docr::API.new(Docr::Client.new)
  cr = UUID.random.to_s
  client = MockServerClient::Client.new(port: 1090)

  Spec.before_suite do
    containers = Docr.command.ps.execute

    unless containers.find { |c| c.image == "mockserver/mockserver:latest" }
      Docr.command.run
        .image("mockserver/mockserver:latest")
        .port("1090", "1080/tcp")
        .rm
        .name(cr.not_nil!)
        .execute
      sleep 2
    else
      # Already a mockserver running, just re-use it
      cr = nil
    end
  end

  Spec.after_suite do
    api.containers.stop(cr.not_nil!) if cr
  end

  Spec.after_each do
    client.reset
  end

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
    regular_client = HTTP::Client.new("localhost", 1090)

    resp = regular_client.get("/does/not/exist")
    resp.status_code.should eq 404

    requests = client.retrieve(type: "requests").as(Array(MockServerClient::HttpRequest))
    requests.size.should eq 1
    req = requests[0]
    req.path.should eq "/does/not/exist"
    req.method.should eq "GET"
  end
end
