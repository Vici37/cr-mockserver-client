require "./mockserver/**"

module MockServerClient
  class MockServerApiException < Exception
  end

  class Client
    def initialize(@mockserver_url : String = "localhost", @port : Int32 = 1080)
      @logger = ::Log.for(Client)
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

    def request(**kwargs)
      HttpRequest.new(**kwargs)
    end

    def response(**kwargs)
      HttpResponse.new(**kwargs)
    end

    def forward(**kwargs)
      HttpForward.new(**kwargs)
    end

    def expectation(**kwargs)
      exp = Expectation.new(**kwargs)
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

    def verify(expectation : Expectation | ExpectationId | HttpRequest | String, **kwargs)
      raise "Require to specify at_least parameter and / or at_most" if kwargs.empty? || (!kwargs.has_key?(:at_most) && !kwargs.has_key?(:at_least))

      if expectation.is_a?(Expectation)
        resp = client_put("/mockserver/verify", Verification.new(
          expectation_id: ExpectationId.new(expectation),
          times: VerificationTimes.new(**kwargs)).to_json
        )
      elsif expectation.is_a?(ExpectationId)
        resp = client_put("/mockserver/verify", Verification.new(
          expectation_id: expectation,
          times: VerificationTimes.new(**kwargs)).to_json
        )
      elsif expectation.is_a?(HttpRequest)
        resp = client_put("/mockserver/verify", Verification.new(
          http_request: expectation,
          times: VerificationTimes.new(**kwargs)).to_json
        )
      elsif expectation.is_a?(String)
        resp = client_put("/mockserver/verify", Verification.new(
          expectation_id: ExpectationId.new(expectation),
          times: VerificationTimes.new(**kwargs)).to_json
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
        verification = VerificationSequence.new(http_requests: sequence)
      elsif sequence.is_a?(Array(Expectation))
        verification = VerificationSequence.new(http_requests: sequence.map(&.http_request!))
      end

      resp = client_put("/mockserver/verifySequence", verification.to_json)

      return true if resp.not_nil!.status_code == 202
      return false if resp.not_nil!.status_code == 406
      raise "Bad request format: #{resp.body}"
    end

    # Calls to mock server are "successful" with these response codes
    SAFE_STATUS_CODE = [406] + (200..299).to_a

    private def client_put(path, body = nil)
      url = "#{@mockserver_url}:#{@port}#{path}"
      @logger.debug { "Making put request to mockserver to #{url}" }
      resp = HTTP::Client.put(url, nil, body)
      @logger.debug { "Received status code #{resp.status_code}, considered successful: #{SAFE_STATUS_CODE.includes?(resp.status_code)}" }
      return resp if SAFE_STATUS_CODE.includes?(resp.status_code)
      raise MockServerApiException.new(resp.body)
    end
  end
end
