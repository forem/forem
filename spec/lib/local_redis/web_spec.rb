require "spec_helper"
require "tmpdir"
require "fileutils"
require "rbconfig"
require_relative "../../../lib/local_redis/web"

RSpec.describe LocalRedis::Web do
  let(:process_state) { {} }
  let(:directory) { Dir.mktmpdir("forem-web-", "/tmp") }
  let(:web_pid_path) { File.join(directory, "web.pid") }
  let(:cache_pid_path) { File.join(directory, "cache.pids") }

  after do
    if process_state[:pid]
      Process.kill("KILL", -process_state[:pid])
      Process.waitpid(process_state[:pid])
    end
  rescue Errno::ESRCH, Errno::ECHILD
    nil
  ensure
    FileUtils.remove_entry(directory)
  end

  def wait_until
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 6
    until yield
      raise "Timed out waiting for supervisor" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

      sleep 0.02
    end
  end

  def launch(web_command, cache_command)
    supervisor = described_class.new(command: web_command, cache_commands: { redis: cache_command })
    process_state[:pid] = fork do
      Process.setpgrp
      exit! supervisor.run
    end
  end

  it "restarts a failed cache process while keeping the same web process alive, then forwards TERM" do
    web_command = [RbConfig.ruby, "-e", "File.write(ARGV[0], Process.pid); sleep 30", web_pid_path]
    cache_command = [RbConfig.ruby, "-e", "File.open(ARGV[0], 'a') { |f| f.puts Process.pid }; exit", cache_pid_path]
    launch(web_command, cache_command)
    wait_until { File.exist?(web_pid_path) && File.exist?(cache_pid_path) && File.readlines(cache_pid_path).size >= 2 }
    web_pid = File.read(web_pid_path).to_i
    expect(Process.kill(0, web_pid)).to eq(1)
    Process.kill("TERM", process_state[:pid])
    result = nil
    wait_until { result = Process.waitpid2(process_state[:pid], Process::WNOHANG) }
    process_state[:pid] = nil
    expect(result.last.exitstatus).to eq(0)
    expect { Process.kill(0, web_pid) }.to raise_error(Errno::ESRCH)
  end

  it "returns the web exit status and terminates the auxiliary process" do
    cache_command = [RbConfig.ruby, "-e", "File.write(ARGV[0], Process.pid); sleep 30", cache_pid_path]
    launch([RbConfig.ruby, "-e", "sleep 0.3; exit 7"], cache_command)
    result = nil
    wait_until { result = Process.waitpid2(process_state[:pid], Process::WNOHANG) }
    process_state[:pid] = nil
    cache_pid = File.read(cache_pid_path).to_i
    expect(result.last.exitstatus).to eq(7)
    expect { Process.kill(0, cache_pid) }.to raise_error(Errno::ESRCH)
  end
end
