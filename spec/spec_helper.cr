require "spec"
require "docr"
require "uuid"
require "../src/mockserver-client"

api = Docr::API.new(Docr::Client.new)
mockserver_id = UUID.random.to_s
client = MockServerClient::Client.new(port: 1090)

Spec.before_suite do
  containers = Docr.command.ps.execute

  unless containers.find { |c| c.image =~ /mockserver\/mockserver(:latest)?/ && c.ports.find { |p| p.public_port == 1090 } }
    Docr.command.run
      .image("mockserver/mockserver:latest")
      .port("1090", "1080/tcp")
      .rm
      .name(mockserver_id.not_nil!)
      .execute

    attempts = 0
    while true
      begin
        client.status
        break
      rescue e
        # Connection error, sleep and then try again
        raise e if attempts >= 60

        attempts += 1
        sleep 1
      end
    end
  else
    # Already a mockserver running, just re-use it
    mockserver_id = nil
  end
end

Spec.after_suite do
  api.containers.stop(mockserver_id.not_nil!) if mockserver_id
end

Spec.after_each do
  client.reset
end
