# frozen_string_literal: true

namespace :perf do
  task :rails_load do
    ENV["RAILS_ENV"] ||= "production"
    ENV['RACK_ENV']  = ENV["RAILS_ENV"]
    ENV["DISABLE_SPRING"] = "true"

    ENV["SECRET_KEY_BASE"] ||= "foofoofoo"

    ENV['LOG_LEVEL'] ||= "FATAL"

    require 'rails'

    puts "Booting: #{Rails.env}"

    %W{ . lib test config }.each do |file|
      $LOAD_PATH << File.expand_path(file)
    end

    require 'application'

    Rails.env = ENV["RAILS_ENV"]

    DERAILED_APP = Rails.application

    if DERAILED_APP.respond_to?(:initialized?)
      DERAILED_APP.initialize! unless DERAILED_APP.initialized?
    else
      DERAILED_APP.initialize! unless DERAILED_APP.instance_variable_get(:@initialized)
    end

    if !ENV["DERAILED_SKIP_ACTIVE_RECORD"] && defined? ActiveRecord
      if defined? ActiveRecord::Tasks::DatabaseTasks
        ActiveRecord::Tasks::DatabaseTasks.create_current
      else # Rails 3.2
        raise "No valid database for #{ENV['RAILS_ENV']}, please create one" unless ActiveRecord::Base.connection.active?.inspect
      end

      ActiveRecord::Migrator.migrations_paths = DERAILED_APP.paths['db/migrate'].to_a
      ActiveRecord::Migration.verbose         = true

      if Rails.version >= "6.0"
        ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths, ActiveRecord::SchemaMigration).migrate
      elsif Rails.version.start_with?("5.2")
        ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths).migrate
      else
        ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths, nil)
      end
    end

    DERAILED_APP.config.consider_all_requests_local = true
  end

  task :rack_load do
    puts "You're not using Rails"
    puts "You need to tell derailed how to boot your app"
    puts "In your perf.rake add:"
    puts
    puts "namespace :perf do"
    puts "  task :rack_load do"
    puts "    # DERAILED_APP = your code here"
    puts "  end"
    puts "end"
  end

  task :setup do
    if DerailedBenchmarks.gem_is_bundled?("railties")
      Rake::Task["perf:rails_load"].invoke
    else
      Rake::Task["perf:rack_load"].invoke
    end

    WARM_COUNT  = (ENV['WARM_COUNT'] || 0).to_i
    TEST_COUNT  = (ENV['TEST_COUNT'] || ENV['CNT'] || 1_000).to_i
    PATH_TO_HIT = ENV["PATH_TO_HIT"] || ENV['ENDPOINT'] || "/"
    puts "Endpoint: #{ PATH_TO_HIT.inspect }"

    HTTP_HEADER_PREFIX = "HTTP_".freeze
    RACK_HTTP_HEADERS = ENV.select { |key| key.start_with?(HTTP_HEADER_PREFIX) }

    HTTP_HEADERS = RACK_HTTP_HEADERS.keys.inject({}) do |hash, rack_header_name|
      # e.g. "HTTP_ACCEPT_CHARSET" -> "Accept-Charset"
      header_name = rack_header_name[HTTP_HEADER_PREFIX.size..-1].split("_").map(&:downcase).map(&:capitalize).join("-")
      hash[header_name] = RACK_HTTP_HEADERS[rack_header_name]
      hash
    end
    puts "HTTP headers: #{HTTP_HEADERS}" unless HTTP_HEADERS.empty?

    CURL_HTTP_HEADER_ARGS = HTTP_HEADERS.map { |http_header_name, value| "-H \"#{http_header_name}: #{value}\"" }.join(" ")

    require 'rack/test'
    require 'rack/file'

    DERAILED_APP = DerailedBenchmarks.add_auth(Object.class_eval { remove_const(:DERAILED_APP) })
    if server = ENV["USE_SERVER"]
      @port = (3000..3900).to_a.sample
      puts "Port: #{ @port.inspect }"
      puts "Server: #{ server.inspect }"
      thread = Thread.new do
        Rack::Server.start(app: DERAILED_APP, :Port => @port, environment: "none", server: server)
      end
      sleep 1

      def call_app(path = File.join("/", PATH_TO_HIT))
        cmd = "curl #{CURL_HTTP_HEADER_ARGS} 'http://localhost:#{@port}#{path}' -s --fail 2>&1"
        response = `#{cmd}`
        unless $?.success?
          STDERR.puts "Couldn't call app."
          STDERR.puts "Bad request to #{cmd.inspect} \n\n***RESPONSE***:\n\n#{ response.inspect }"

          FileUtils.mkdir_p("tmp")
          File.open("tmp/fail.html", "w+") {|f| f.write response }

          `open #{File.expand_path("tmp/fail.html")}` if ENV["DERAILED_DEBUG"]

          exit(1)
        end
      end
    else
      @app = Rack::MockRequest.new(DERAILED_APP)

      def call_app
        response = @app.get(PATH_TO_HIT, RACK_HTTP_HEADERS)
        if response.status != 200
          STDERR.puts "Couldn't call app. Bad request to #{PATH_TO_HIT}! Resulted in #{response.status} status."
          STDERR.puts "\n\n***RESPONSE BODY***\n\n"
          STDERR.puts response.body

          FileUtils.mkdir_p("tmp")
          File.open("tmp/fail.html", "w+") {|f| f.write response.body }

          `open #{File.expand_path("tmp/fail.html")}` if ENV["DERAILED_DEBUG"]

          exit(1)
        end
        response
      end
    end
    if WARM_COUNT > 0
      puts "Warming up app: #{WARM_COUNT} times"
      WARM_COUNT.times { call_app }
    end
  end
end
