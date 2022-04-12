require "./spec_helper"

describe MockServerClient do
  client = MockServerClient::Client.new(port: 1090)
  regular_client = HTTP::Client.new("localhost", 1090)

  it "creates and retrieves expectations" do
    resp = client.expectation(
      http_request: client.request(
        path: "/hello/world",
        method: "GET",
      ),
      http_response: client.response(
        body: "world!"
      )
    )

    resp.size.should eq 1
    resp[0].id.should_not be_nil
    resp[0].http_request!.path.should eq "/hello/world"

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
    orig_stats = client.status

    stats = client.bind(0)

    (stats.ports - orig_stats.ports).size.should eq 1
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
    exps = client.expectation(http_request: client.request(path: "/nope"), http_response: client.response(status_code: 200))
    regular_client.get("/nope")
    req_resps = client.retrieve("request_responses").as(Array(MockServerClient::RequestResponse))

    req_resps.size.should eq 2
    req_resps[0].http_request.path.should eq "/"
    req_resps[0].http_response.status_code.should eq 404

    req_resps[1].http_request.path.should eq "/nope"
    req_resps[1].http_response.status_code.should eq 200
    expected = req_resps[1]

    client.retrieve("recorded_expectations").should be_empty # no proxy expectations

    client.retrieve("logs").empty?.should be_false

    # Now get the requests_responses for the expectation we have
    client.retrieve_requests(exps[0])
    req_resps = client.retrieve_request_responses(exps[0])
    req_resps[0].should eq expected
  end

  it "retrieves active expectations" do
    exp = client.expectation(
      http_request: client.request(path: "/yup"),
      http_response: client.response(status_code: 200)
    )

    regular_client.get("/yup").status_code.should eq 200

    reqs = client.retrieve_requests
    reqs.size.should eq 1

    actual_exp = client.retrieve_active_expectations(exp[0])

    actual_exp.size.should eq 1
    exp.should eq actual_exp
  end

  it "forwards" do
    client.expectation(
      http_request: client.request(path: "/"),
      http_forward: client.forward(host: "google.com", port: 443, scheme: "HTTPS")
    )

    resp = regular_client.get("/")
    (resp.body.size > 0).should be_true
  end
end
