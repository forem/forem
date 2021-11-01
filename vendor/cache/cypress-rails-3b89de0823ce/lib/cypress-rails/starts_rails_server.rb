require_relative "tracks_resets"
require_relative "server"

module CypressRails
  class StartsRailsServer
    def call(host:, port:, transactional_server:)
      configure_rails_to_run_our_state_reset_on_every_request!(transactional_server)
      app = create_rack_app
      Server.new(app, host: host, port: port).tap do |server|
        server.boot
      end
    end

    def configure_rails_to_run_our_state_reset_on_every_request!(transactional_server)
      Rails.application.executor.to_run do
        TracksResets.instance.reset_state_if_needed(transactional_server)
      end
    end

    def create_rack_app
      Rack::Builder.new do
        map "/cypress_rails_reset_state" do
          run lambda { |env|
            TracksResets.instance.reset_needed!
            [202, {"Content-Type" => "text/plain"}, ["Accepted"]]
          }
        end
        map "/" do
          run Rails.application
        end
      end
    end
  end
end
