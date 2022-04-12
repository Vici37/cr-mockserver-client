# Crystal MockServer Client Library

This library aims to provide a crystal library that can interact with [MockServer](https://www.mock-server.com/#what-is-mockserver).
Consider using the [WebMock shard](https://github.com/manastech/webmock.cr) instead of mockserver for easier testing and development.
Mockserver is good for a multi-server testing setup or if you want to test your crystal server in production mode using an external
testing framework.

Note: development on this library requires docker, as a mockserver container is used during testing.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     mockserver-client:
       github: vici37/cr-mockserver-client
   ```

2. Run `shards install`

## Usage

```crystal
require "mockserver-client"

# Create a client, defaults to using localhost:1080
client = MockServerClient::Client.new
regular_client = HTTP::Client.new("localhost", 8080)

# Have mockserver bind to a new port
client.bind(8080)

regular_client.get("/") # 404

client.expectation(
  # client.request is a handy wrapper around MockServerClient::HttpRequest.new(...)
  http_request: client.request(path: "/", method: "GET"),
  # same with client.response for HttpResponse
  http_response: client.response(status_code: 200, body: "success!")
)

regular_client.get("/") # 200, body: "success!"

# The `expectation` call is the same as:
req = MockServerClient::HttpRequest.new(path: "/", method: "GET")
resp = MockServerClient::HttpResponse.new(status_code: 200, body: "success!")
exp = MockServerClient::Expectation.new(req, resp)
client.expectation(exp)

# Due to most fields within mockserver being nullable, you can always use a `!` suffixed
# call to get the non-nil value
exp.http_request.class # HttpRequest | Nil
exp.http_request!.class # HttpRequest
```
