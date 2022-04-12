require "json"

module MockServerClient
  macro json_record(name, *properties)
    struct {{name.id}}
      include JSON::Serializable

      {% for property in properties %}
        {% if property.is_a?(TypeDeclaration) %}
        @[JSON::Field(key: "{{property.var.id.camelcase(lower: true)}}")]
        getter {{property}}

        {% if property.type.id.ends_with?("::Nil") %}
        def {{property.var.id}}!
          @{{property.var.id}}.not_nil!
        end
        {% end %}
        {% else %}
        @[JSON::Field(key: "{{property.target.id.camelcase(lower: true)}}")]
        getter {{property}}
        {% end %}

      {% end %}

      def initialize({{
                       *properties.map do |field|
                         "@#{field.id}".id
                       end
                     }})
      end

      {{yield}}
    end
  end

  json_record Expectation,
    http_request : HttpRequest? = nil,
    http_response : HttpResponse? = nil,
    http_forward : HttpForward? = nil,
    http_override_forward : HttpOverrideForward? = nil,
    id : String? = nil,
    times : Times? = nil,
    priority : Int32? = nil

  json_record ExpectationId,
    id : String do
    def initialize(exp : Expectation)
      @id = exp.id!
    end
  end

  alias BodyMatchers = String | JSON::Any | JsonPathBodyMatcher | BinaryBodyMatcher |
                       ParametersBodyMatcher | RegexBodyMatcher | StringBodyMatcher |
                       XpathBodyMatcher | XmlBodyMatcher | JsonBodyMatcher

  alias BodyResponses = String | JSON::Any | BinaryBodyMatcher | JsonBodyMatcher | JsonPathBodyMatcher |
                        ParametersBodyMatcher | RegexBodyMatcher | StringBodyMatcher | XmlBodyMatcher |
                        XpathBodyMatcher

  json_record HttpRequest,
    method : String? = nil,
    path : String? = nil,
    body : BodyMatchers? = nil,
    path_parameters : Hash(String, Array(String))? = nil,
    query_string_parameters : Hash(String, Array(String))? = nil,
    headers : Hash(String, Array(String))? = nil,
    cookies : Hash(String, String)? = nil,
    socket_address : SocketAddress? = nil,
    secure : Bool = false,
    keep_alive : Bool = true

  json_record HttpResponse,
    status_code : Int32? = nil,
    body : BodyResponses? = nil,
    headers : Hash(String, Array(String))? = nil,
    cookies : Hash(String, String)? = nil,
    connection_options : ConnectionOptions? = nil,
    delay : Delay? = nil do
    include JSON::Serializable
  end

  json_record Delay,
    time_unit : String,
    value : Int32

  json_record SocketAddress,
    host : String,
    port : Int32?,
    scheme : String

  json_record Ports,
    ports : Array(Int32)

  json_record ConnectionOptions,
    suppress_content_length_header : Bool? = nil,
    content_length_header_override : Bool? = nil,
    suppress_connection_header : Bool? = nil,
    chunk_size : Int32? = nil,
    keep_alive_override : Bool? = nil,
    close_socket : Bool? = nil,
    close_socket_delay : Delay? = nil

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

  json_record BinaryBodyMatcher,
    base_64_bytes : String,
    content_type : String? = nil,
    type = BodyTypes::BINARY

  json_record JsonBodyMatcher,
    json : JSON::Any,
    content_type : String? = nil,
    match_type : String? = nil,
    type = BodyTypes::JSON

  json_record JsonPathBodyMatcher,
    json_path : String,
    type = BodyTypes::JSON_PATH

  json_record ParametersBodyMatcher,
    parameters : Hash(String, Array(String)),
    type = BodyTypes::PARAMETERS

  json_record RegexBodyMatcher,
    regex : String,
    type = BodyTypes::REGEX

  json_record StringBodyMatcher,
    string : String,
    content_type : String? = nil,
    sub_string : Bool? = nil,
    type = BodyTypes::STRING

  json_record XmlBodyMatcher,
    xml : String,
    content_type : String? = nil,
    type = BodyTypes::XML

  json_record XpathBodyMatcher,
    xpath : String,
    type = BodyTypes::XPATH

  json_record Verification,
    expectation_id : ExpectationId? = nil,
    http_request : HttpRequest? = nil,
    times : VerificationTimes? = nil

  json_record VerificationTimes,
    at_least : Int32? = nil,
    at_most : Int32? = nil

  json_record VerificationSequence,
    expectation_ids : Array(ExpectationId)? = nil,
    http_requests : Array(HttpRequest)? = nil

  json_record RequestResponse,
    timestamp : String,
    http_request : HttpRequest,
    http_response : HttpResponse

  json_record Times,
    remaining_times : Int32? = nil,
    unlimited : Bool? = true

  json_record HttpForward,
    host : String? = nil,
    port : Int32? = nil,
    scheme : String? = nil

  json_record HttpOverrideForward,
    delay : Delay? = nil,
    http_request : HttpRequest? = nil,
    http_response : HttpResponse? = nil
end
