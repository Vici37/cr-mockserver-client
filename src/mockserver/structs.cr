require "json"

module MockServerClient
  record Expectation,
    httpRequest : HttpRequest,
    httpResponse : HttpResponse,
    id : String? = nil,
    priority : Int32? = nil do
    include JSON::Serializable
  end

  record ExpectationId,
    id : String do
    include JSON::Serializable
  end

  record HttpRequest,
    method : String,
    path : String,
    body : String? = nil,
    pathParameters : Hash(String, Array(String))? = nil,
    queryStringParameters : Hash(String, Array(String))? = nil,
    headers : Hash(String, Array(String))? = nil,
    cookies : Hash(String, String)? = nil,
    socketAddress : SocketAddress? = nil,
    secure : Bool = false,
    keepAlive : Bool = false do
    include JSON::Serializable
  end

  record HttpResponse,
    statusCode : Int32,
    body : String,
    headers : Hash(String, Array(String))? = nil,
    cookies : Hash(String, String)? = nil,
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
end
