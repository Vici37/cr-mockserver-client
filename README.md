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

client.expectation(path: "/", method: "GET", responseStatusCode: 200, responseBody: "success!")

regular_client.get("/") # 200, body: "success!"

# The `expectation` call is the same as:
req = MockServerClient::HttpRequest.new(path: "/", method: "GET")
resp = MockServerClient::HttpResponse.new(statusCode: 200, body: "success!")
exp = MockServerClient::Expectation.new(req, resp)
client.expectation(exp)
```
