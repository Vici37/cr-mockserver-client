require "json"

module MockServerClient
  record Expectation,
    httpRequest : HttpRequest,
    httpResponse : HttpResponse,
    id : String? = nil,
    priority : Int32? = nil do
    include JSON::Serializable

    def id!
      @id.not_nil!
    end
  end

  record ExpectationId,
    id : String do
    include JSON::Serializable

    def initialize(exp : Expectation)
      @id = exp.id.not_nil!
    end
  end

  alias BodyMatchers = String | JSON::Any | JsonPathBodyMatcher | BinaryBodyMatcher |
                       ParametersBodyMatcher | RegexBodyMatcher | StringBodyMatcher |
                       XpathBodyMatcher | XmlBodyMatcher | JsonBodyMatcher

  alias BodyResponses = String | JSON::Any | BinaryBodyMatcher | JsonBodyMatcher | StringBodyMatcher | XmlBodyMatcher

  record HttpRequest,
    method : String? = nil,
    path : String? = nil,
    body : BodyMatchers? = nil,
    pathParameters : Hash(String, Array(String))? = nil,
    queryStringParameters : Hash(String, Array(String))? = nil,
    headers : Hash(String, Array(String))? = nil,
    cookies : Hash(String, String)? = nil,
    socketAddress : SocketAddress? = nil,
    secure : Bool = false,
    keepAlive : Bool = true do
    include JSON::Serializable
  end

  record HttpResponse,
    statusCode : Int32,
    body : BodyResponses?,
    headers : Hash(String, Array(String))? = nil,
    cookies : Hash(String, String)? = nil,
    connectionOptions : ConnectionOptions? = nil,
    delay : Delay? = nil do
    include JSON::Serializable
  end

  record Delay,
    timeUnit : String,
    value : Int32 do
    include JSON::Serializable
  end

  record SocketAddress,
    host : String,
    port : Int32?,
    scheme : String do
    include JSON::Serializable
  end

  record Ports,
    ports : Array(Int32) do
    include JSON::Serializable
  end

  record ConnectionOptions,
    suppressContentLengthHeader : Bool? = nil,
    contentLengthHeaderOverride : Bool? = nil,
    suppressConnectionHeader : Bool? = nil,
    chunkSize : Int32? = nil,
    keepAliveOverride : Bool? = nil,
    closeSocket : Bool? = nil,
    closeSocketDelay : Delay? = nil do
    include JSON::Serializable
  end

  enum BodyTypes
    BINARY
    XML
    JSON
    JSON_PATH
    PARAMETERS
    REGEX
    STRING
    XPATH
  end

  class BinaryBodyMatcher
    include JSON::Serializable

    @type = BodyTypes::BINARY
    property base64Bytes : String
    property contentType : String?

    def initialize(@base64Bytes, @contentType = nil)
    end
  end

  class JsonBodyMatcher
    include JSON::Serializable
    @type = BodyTypes::JSON
    property json : JSON::Any
    property contentType : String?
    property matchType : String?

    def initialize(@json, @contentType = nil, @matchType = nil)
    end
  end

  class JsonPathBodyMatcher
    include JSON::Serializable

    @type = BodyTypes::JSON_PATH
    property jsonPath : String

    def initialize(@jsonPath)
    end
  end

  class ParametersBodyMatcher
    include JSON::Serializable

    @type = BodyTypes::PARAMETERS
    property parameters : Hash(String, Array(String))

    def initialize(@parameters)
    end
  end

  class RegexBodyMatcher
    include JSON::Serializable

    @type = BodyTypes::REGEX
    property regex : String

    def initialize(@regex)
    end
  end

  class StringBodyMatcher
    include JSON::Serializable

    @type = BodyTypes::STRING
    property string : String
    property contentType : String?
    property subString : Bool?

    def initialize(@string, @contentType = nil, @subString = nil)
    end
  end

  class XmlBodyMatcher
    include JSON::Serializable

    @type = BodyTypes::XML
    property xml : String
    property contentType : String?

    def initialize(@xml, @contentType = nil)
    end
  end

  class XpathBodyMatcher
    include JSON::Serializable

    @type = BodyTypes::XPATH
    property xpath : String

    def initialize(@xpath)
    end
  end

  record Verification,
    expectationId : ExpectationId? = nil,
    httpRequest : HttpRequest? = nil,
    times : VerificationTimes? = nil do
    include JSON::Serializable
  end

  record VerificationTimes,
    atLeast : Int32? = nil,
    atMost : Int32? = nil do
    include JSON::Serializable
  end

  record VerificationSequence,
    expectationIds : Array(ExpectationId)? = nil,
    httpRequests : Array(HttpRequest)? = nil do
    include JSON::Serializable
  end
end
