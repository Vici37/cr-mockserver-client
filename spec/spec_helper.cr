require "spec"
require "docr"
require "uuid"
require "../src/cr-mockserver-client"

api = Docr::API.new(Docr::Client.new)
mockserver_id = UUID.random.to_s

Spec.before_suite do
  containers = Docr.command.ps.execute

  unless containers.find { |c| c.image == "mockserver/mockserver:latest" }
    Docr.command.run
      .image("mockserver/mockserver:latest")
      .port("1090", "1080/tcp")
      .rm
      .name(mockserver_id.not_nil!)
      .execute
    sleep 2
  else
    # Already a mockserver running, just re-use it
    mockserver_id = nil
  end
end

Spec.after_suite do
  api.containers.stop(mockserver_id.not_nil!) if mockserver_id
end

client = MockServerClient::Client.new(port: 1090)
Spec.after_each do
  client.reset
end
