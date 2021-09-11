require "./mockserver/**"

module MockServerClient
  class MockServerApiException < Exception
  end

  class Client
    def initialize(@mockserver_url : String = "localhost", @port : Int32 = 1080)
    end

    def clear(id : String)
      client_put("/mockserver/clear", ExpectationId.new(id: id).to_json)
    end

    def clear(request : HttpRequest)
      client_put("/mockserver/clear", request.to_json)
    end

    def reset
      client_put("/mockserver/reset")
    end

    def retrieve_active_expectations(exp : Expectation? = nil)
      retrieve("active_expectations", exp.nil? ? nil : exp.to_json).as(Array(Expectation))
    end

    def retrieve_requests(exp : Expectation? = nil)
      retrieve("requests", exp.nil? ? nil : exp.to_json).as(Array(HttpRequest))
    end

    def retrieve_logs
      retrieve("logs").as(Array(String))
    end

    def retrievie_recorded_expectations(exp : Expectation? = nil)
      retrieve("recorded_expectations", exp.nil? ? nil : exp.to_json).as(Array(Expectation))
    end

    def retrieve_request_responses(exp : Expectation? = nil)
      retrieve("request_responses", exp.nil? ? nil : exp.to_json).as(Array(RequestResponse))
    end

    def retrieve(type : String = "requests", body = nil)
      resp = client_put("/mockserver/retrieve?type=#{type}", body)

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
      requestPathParameters : Hash(String, Array(String))? = nil,
      requestHeaders : Hash(String, Array(String))? = nil,
      requestCookies : Hash(String, String)? = nil,
      requestQueryParams : Hash(String, Array(String))? = nil,

      forwardHost : String? = nil,
      forwardPort : Int32? = nil,
      forwardScheme : String? = nil,

      responseStatusCode : Int32? = nil,
      responseBody : BodyResponses? = nil,
      responseHeaders : Hash(String, Array(String))? = nil,
      responseCookies : Hash(String, String)? = nil,
      delay : Delay? = nil
    )
      req = nil
      if path || method || requestBody || requestPathParameters || requestQueryParams || requestHeaders || requestCookies
        req = HttpRequest.new(path: path, method: method, body: requestBody,
          pathParameters: requestPathParameters, queryStringParameters: requestQueryParams,
          headers: requestHeaders, cookies: requestCookies)
      end

      resp = nil
      if responseStatusCode || responseBody || responseHeaders || delay
        resp = HttpResponse.new(statusCode: responseStatusCode, body: responseBody,
          headers: responseHeaders, cookies: responseCookies, delay: delay)
      end

      forward = nil
      if forwardHost || forwardPort || forwardScheme
        forward = HttpForward.new(host: forwardHost, port: forwardPort, scheme: forwardScheme)
      end

      exp = Expectation.new(req, resp, forward)
      expectation(exp)
    end

    def expectation(expectation : Expectation)
      resp = client_put("/mockserver/expectation", expectation.to_json)
      Array(Expectation).from_json(resp.body)
    end

    def status
      resp = client_put("/mockserver/status")
      Ports.from_json(resp.body)
    end

    def bind(port : Int32 | Array(Int32))
      if port.is_a?(Int32)
        p = Ports.new(ports: [port])
      else
        p = Ports.new(ports: port)
      end
      client_put("/mockserver/bind", p.to_json)

      status
    end

    def verify(expectation : Expectation | HttpRequest | String, atLeast : Int32? = nil, atMost : Int32? = nil)
      raise "Require to specify atLeast parameter and / or atMost" if atMost.nil? && atLeast.nil?

      if expectation.is_a?(Expectation)
        resp = client_put("/mockserver/verify", Verification.new(
          expectationId: ExpectationId.new(expectation),
          times: VerificationTimes.new(atMost: atMost, atLeast: atLeast)).to_json
        )
      elsif expectation.is_a?(HttpRequest)
        resp = client_put("/mockserver/verify", Verification.new(
          httpRequest: expectation,
          times: VerificationTimes.new(atMost: atMost, atLeast: atLeast)).to_json
        )
      elsif expectation.is_a?(String)
        resp = client_put("/mockserver/verify", Verification.new(
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
        verification = VerificationSequence.new(httpRequests: sequence.map { |e| e.httpRequest! })
      end

      resp = client_put("/mockserver/verifySequence", verification.to_json)

      return true if resp.not_nil!.status_code == 202
      return false if resp.not_nil!.status_code == 406
      raise "Bad request format: #{resp.body}"
    end

    # Calls to mock server are "successful" with these response codes
    SAFE_STATUS_CODE = [406] + (200..299).to_a

    private def client_put(path, body = nil)
      resp = HTTP::Client.put("#{@mockserver_url}:#{@port}#{path}", nil, body)
      return resp if SAFE_STATUS_CODE.includes?(resp.status_code)
      raise MockServerApiException.new(resp.body)
    end
  end
end
