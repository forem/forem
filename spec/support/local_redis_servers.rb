require "tmpdir"
require "fileutils"
require "redis"

RSpec.shared_context "with real Redis" do
  around do |example|
    fake_enabled = defined?(FakeRedis) && FakeRedis.enabled?
    FakeRedis.disable if fake_enabled
    example.run
  ensure
    FakeRedis.enable if fake_enabled
  end
end

# Actual Redis is intentional: mocks/fakeredis cannot exercise RESP3 tracking,
# script atomicity, PTTL, or invalidation delivery across connections.
class LocalRedisServers
  attr_reader :directory

  def initialize
    @directory = Dir.mktmpdir("forem-l1-", "/tmp")
    @servers = {}
  end

  def start(name, *options)
    socket = File.join(directory, "#{name}.sock")
    url = "unix://#{socket}"
    pid = Process.spawn(ENV.fetch("REDIS_SERVER", "redis-server"), "--port", "0", "--unixsocket", socket,
                        "--save", "", "--appendonly", "no", *options, out: File::NULL, err: File::NULL)
    @servers[pid] = url
    client = Redis.new(url: url, timeout: 0.1, reconnect_attempts: 0)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
    loop do
      client.ping
      break
    rescue Redis::BaseError
      raise "Test Redis did not start" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

      sleep 0.01
    end
    client.close
    url
  end

  def close
    @servers.each do |pid, url|
      shutdown(url)
      begin
        Process.kill("TERM", pid)
      rescue Errno::ESRCH
        nil
      end
      Process.waitpid(pid)
    rescue Errno::ECHILD
      nil
    end
    FileUtils.remove_entry(directory)
  end

  private

  def shutdown(url)
    # SHUTDOWN exits immediately; TERM waits for Redis's next server cron tick.
    client = Redis.new(url: url, timeout: 0.1, reconnect_attempts: 0)
    client.shutdown
  rescue Redis::BaseError, SystemCallError
    # Keep signal cleanup for unavailable servers or a disabled SHUTDOWN command.
    nil
  ensure
    client&.close
  end
end
