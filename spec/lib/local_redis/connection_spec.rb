require "spec_helper"
require "open3"
require "json"
require "rbconfig"
require_relative "../../support/local_redis_servers"
require_relative "../../../lib/local_redis/connection"

RSpec.describe LocalRedis::Connection do
  include_context "with real Redis"

  it "skips local spans while preserving hosted Redis tracing with the actual Datadog integration" do
    servers = LocalRedisServers.new
    url = servers.start("tracing")
    source = <<~RUBY
      require 'json'
      require 'redis'
      require 'redis-client'
      require 'ddtrace'
      require_relative 'lib/local_redis/connection'
      writer = Class.new do
        attr_reader :spans
        def initialize; @spans = 0; end
        def write(trace); @spans += trace.spans.size; end
        def stop; end
      end.new
      Datadog.configure do |c|
        c.tracing.enabled = true
        c.tracing.writer = writer
        c.tracing.instrument :redis
      end
      local = LocalRedis::Connection.new(ARGV.fetch(0))
      10.times { raise 'bad result' unless local.eval('return 1', keys: []) == 1 }
      raise 'local spans leaked' unless writer.spans == 0
      Redis.new(url: ARGV.fetch(0)).ping
      puts JSON.generate(spans: writer.spans)
      local.close
    RUBY
    env = { "DD_INSTRUMENTATION_TELEMETRY_ENABLED" => "false", "DD_TRACE_STARTUP_LOGS" => "false" }
    stdout, stderr, status = Open3.capture3(env, RbConfig.ruby, "-rbundler/setup", "-e", source, url)
    expect(status).to be_success, stderr
    expect(JSON.parse(stdout)).to eq("spans" => 1)
  ensure
    servers&.close
  end
end
