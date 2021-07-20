require "./mockserver/**"

module MockServerClient
  class Client
    def initialize(mockserver_url : String = "localhost", port : Int32 = 1080)
      @client = HTTP::Client.new(mockserver_url, port)
    end

    def clear(id : String)
      @client.put("/mockserver/clear", nil, ExpectationId.new(id: id).to_json)
    end

    def clear(request : HttpRequest)
      @client.put("/mockserver/clear", nil, request.to_json)
    end

    def reset
      @client.put("/mockserver/reset")
    end

    def retrieve(type : String = "requests")
      resp = @client.put("/mockserver/retrieve?type=#{type}")

      case type
      when "active_expectations"
        Array(Expectation).from_json(resp.body)
      when "requests"
        Array(HttpRequest).from_json(resp.body)
      else
        raise "Unsupported or unknown retrieve type #{type}. Supported types are: active_expectations"
      end
    end

    def expectation(
      path : String,
      method : String,
      requestBody : String? = nil,
      requestHeaders : Hash(String, Array(String))? = nil,
      requestQueryParams : Hash(String, Array(String))? = nil,
      pathParameters : Hash(String, Array(String))? = nil,
      cookies : Hash(String, String)? = nil,
      responseStatusCode : Int32 = 200,
      responseBody : String? = nil,
      responseHeaders : Hash(String, Array(String))? = nil,
      delay : Delay? = nil
    )
      req = HttpRequest.new(path: path, method: method, body: requestBody,
        pathParameters: pathParameters, queryStringParameters: requestQueryParams,
        headers: requestHeaders, cookies: cookies)
      resp = HttpResponse.new(statusCode: responseStatusCode, body: responseBody,
        headers: responseHeaders, delay: delay)

      exp = Expectation.new(req, resp)
      expectation(exp)
    end

    def expectation(expectation : Expectation)
      resp = @client.put("/mockserver/expectation", nil, expectation.to_json)
      Array(Expectation).from_json(resp.body)
    end

    def status
      resp = @client.put("/mockserver/status")
      Ports.from_json(resp.body)
    end

    def bind(port : Int32 | Array(Int32))
      if port.is_a?(Int32)
        p = Ports.new(ports: [port])
      else
        p = Ports.new(ports: port)
      end
      @client.put("/mockserver/bind", nil, p.to_json)

      status
    end
  end
end
