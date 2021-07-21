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
      when "logs"
        resp.body.split("------------------------------------")
      when "recorded_expectations"
        Array(Expectation).from_json(resp.body)
      when "request_responses"
        Array(RequestResponse).from_json(resp.body)
      else
        raise "Unsupported or unknown retrieve type #{type}. Supported types are: active_expectations"
      end
    end

    def expectation(
      path : String? = nil,
      method : String? = nil,
      requestBody : BodyMatchers? = nil,
      requestHeaders : Hash(String, Array(String))? = nil,
      requestQueryParams : Hash(String, Array(String))? = nil,
      pathParameters : Hash(String, Array(String))? = nil,
      cookies : Hash(String, String)? = nil,
      responseStatusCode : Int32 = 200,
      responseBody : BodyResponses? = nil,
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

    def verify(expectation : Expectation | HttpRequest | String, atLeast : Int32? = nil, atMost : Int32? = nil)
      raise "Require to specify atLeast parameter and / or atMost" if atMost.nil? && atLeast.nil?

      if expectation.is_a?(Expectation)
        resp = @client.put("/mockserver/verify", nil, Verification.new(
          expectationId: ExpectationId.new(expectation),
          times: VerificationTimes.new(atMost: atMost, atLeast: atLeast)).to_json
        )
      elsif expectation.is_a?(HttpRequest)
        resp = @client.put("/mockserver/verify", nil, Verification.new(
          httpRequest: expectation,
          times: VerificationTimes.new(atMost: atMost, atLeast: atLeast)).to_json
        )
      elsif expectation.is_a?(String)
        resp = @client.put("/mockserver/verify", nil, Verification.new(
          expectationId: ExpectationId.new(expectation),
          times: VerificationTimes.new(atMost: atMost, atLeast: atLeast)).to_json
        )
      else
        raise "No handler for type #{expectation.class}"
      end

      return true if resp.not_nil!.status_code == 202
      return false if resp.not_nil!.status_code == 406
      raise "Bad request format: #{resp.body}"
    end

    def verify_sequence(sequence : Array(HttpRequest) | Array(Expectation))
      if sequence.is_a?(Array(HttpRequest))
        verification = VerificationSequence.new(httpRequests: sequence)
      elsif sequence.is_a?(Array(Expectation))
        verification = VerificationSequence.new(httpRequests: sequence.map { |e| e.httpRequest })
      end

      resp = @client.put("/mockserver/verifySequence", nil, verification.to_json)

      return true if resp.not_nil!.status_code == 202
      return false if resp.not_nil!.status_code == 406
      raise "Bad request format: #{resp.body}"
    end
  end
end
