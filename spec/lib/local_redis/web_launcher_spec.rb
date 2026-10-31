require "spec_helper"
require "open3"
require "json"
require "rbconfig"
require_relative "../../support/local_redis_servers"
require_relative "../../../lib/local_redis/web"

RSpec.describe LocalRedis::Web do
  include_context "with real Redis"

  let(:servers) { LocalRedisServers.new }
  let(:socket) { File.join(servers.directory, "launcher.sock") }
  let(:local_url) { "unix://#{socket}" }
  let(:process_state) { {} }

  after do
    if process_state[:pid]
      Process.kill("TERM", process_state[:pid])
      Process.waitpid(process_state[:pid])
    end
  rescue Errno::ESRCH, Errno::ECHILD
    nil
  ensure
    servers.close
  end

  it "starts a bounded private LFU Redis without TCP or persistence" do
    env = { "LOCAL_REDIS_URL" => local_url, "LOCAL_REDIS_MAXMEMORY" => "16mb" }
    process_state[:pid] = Process.spawn(env, RbConfig.ruby, "bin/redis-local-server", out: File::NULL, err: File::NULL)
    client = Redis.new(url: local_url, timeout: 0.1, reconnect_attempts: 0)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
    loop do
      client.ping
      break
    rescue Redis::BaseError
      raise "Launcher did not create a Redis socket" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

      sleep 0.02
    end
    expect(client.config(:get, "maxmemory")).to eq("maxmemory" => (16 * 1024 * 1024).to_s)
    expect(client.config(:get, "maxmemory-policy")).to eq("maxmemory-policy" => "allkeys-lfu")
    expect(client.config(:get, "port")).to eq("port" => "0")
    expect(client.config(:get, "save")).to eq("save" => "")
    expect(client.config(:get, "appendonly")).to eq("appendonly" => "no")
    expect(File.stat(socket).mode & 0o777).to eq(0o700)
  ensure
    client&.close
  end

  it "rejects an unlimited memory budget" do
    env = { "LOCAL_REDIS_URL" => local_url, "LOCAL_REDIS_MAXMEMORY" => "0" }
    _stdout, stderr, status = Open3.capture3(env, RbConfig.ruby, "bin/redis-local-server")
    expect(status).not_to be_success
    expect(stderr).to include("must be a positive byte count")
    expect(File.exist?(socket)).to be(false)
  end

  it "executes the original Puma command when local caching is disabled" do
    shim = File.join(servers.directory, "bundle")
    File.write(shim, "#!#{RbConfig.ruby}\nrequire 'json'\nputs JSON.generate(ARGV)\nexit 23\n")
    File.chmod(0o700, shim)
    env = { "LOCAL_REDIS_URL" => "", "PATH" => "#{servers.directory}:#{ENV.fetch('PATH')}" }
    stdout, _stderr, status = Open3.capture3(env, RbConfig.ruby, "bin/web")
    expect(JSON.parse(stdout)).to eq(["exec", "puma", "-C", "config/puma.rb"])
    expect(status.exitstatus).to eq(23)
  end
end
