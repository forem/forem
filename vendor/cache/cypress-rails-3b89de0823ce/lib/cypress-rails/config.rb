require_relative "env"

module CypressRails
  class Config
    attr_accessor :dir, :host, :port, :base_path, :transactional_server, :cypress_cli_opts, :knapsack

    def initialize(
      dir: Env.fetch("CYPRESS_RAILS_DIR", default: Dir.pwd),
      host: Env.fetch("CYPRESS_RAILS_HOST", default: "127.0.0.1"),
      port: Env.fetch("CYPRESS_RAILS_PORT"),
      base_path: Env.fetch("CYPRESS_RAILS_BASE_PATH", default: "/"),
      transactional_server: Env.fetch("CYPRESS_RAILS_TRANSACTIONAL_SERVER", type: :boolean, default: true),
      cypress_cli_opts: Env.fetch("CYPRESS_RAILS_CYPRESS_OPTS", default: "")
    )
      @dir = dir
      @host = host
      @port = port
      @base_path = base_path
      @transactional_server = transactional_server
      @cypress_cli_opts = cypress_cli_opts
      @knapsack = nil
    end

    def to_s
      <<~DESC

        cypress-rails configuration:
        ============================
         CYPRESS_RAILS_DIR.....................#{dir.inspect}
         CYPRESS_RAILS_HOST....................#{host.inspect}
         CYPRESS_RAILS_PORT....................#{port.inspect}
         CYPRESS_RAILS_BASE_PATH...............#{base_path.inspect}
         CYPRESS_RAILS_TRANSACTIONAL_SERVER....#{transactional_server.inspect}
         CYPRESS_RAILS_CYPRESS_OPTS............#{cypress_cli_opts.inspect}

      DESC
    end
  end
end
