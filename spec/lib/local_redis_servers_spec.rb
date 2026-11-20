require "spec_helper"
require_relative "../support/local_redis_servers"

RSpec.describe LocalRedisServers do
  include_context "with real Redis"

  let(:servers) { described_class.new }
  let(:clients) { [] }

  after do
    clients.each(&:close)
    servers.close if File.directory?(servers.directory)
  end

  def start_server(name, *options)
    url = servers.start(name, *options)
    client = Redis.new(url: url, timeout: 0.1, reconnect_attempts: 0)
    clients << client
    [client.info("server").fetch("process_id").to_i, url]
  end

  it "shuts down and reaps every child before removing the private directory", :aggregate_failures do
    first_pid, first_url = start_server("first")
    second_pid, second_url = start_server("second")
    events = []
    allow(Redis).to receive(:new).and_wrap_original do |original, **kwargs|
      original.call(**kwargs).tap do |client|
        allow(client).to receive(:shutdown).and_wrap_original do |shutdown|
          events << [:shutdown, kwargs[:url]]
          shutdown.call
        end
      end
    end
    allow(Process).to receive(:kill).and_wrap_original do |original, signal, pid|
      events << [:term, pid] if signal == "TERM"
      original.call(signal, pid)
    end

    servers.close

    expect(events).to eq([
                           [:shutdown, first_url],
                           [:term, first_pid],
                           [:shutdown, second_url],
                           [:term, second_pid],
                         ])
    expect { Process.waitpid(first_pid, Process::WNOHANG) }.to raise_error(Errno::ECHILD)
    expect { Process.waitpid(second_pid, Process::WNOHANG) }.to raise_error(Errno::ECHILD)
    expect(File.exist?(servers.directory)).to be(false)
  end

  it "falls back to TERM when SHUTDOWN fails or socket creation raises a system call error", :aggregate_failures do
    disabled_pid, = start_server("no-shutdown", "--rename-command", "SHUTDOWN", "")
    emfile_pid, emfile_url = start_server("emfile")
    allow(Redis).to receive(:new).and_call_original
    allow(Redis).to receive(:new).with(hash_including(url: emfile_url)).and_raise(Errno::EMFILE)

    servers.close

    expect { Process.waitpid(disabled_pid, Process::WNOHANG) }.to raise_error(Errno::ECHILD)
    expect { Process.waitpid(emfile_pid, Process::WNOHANG) }.to raise_error(Errno::ECHILD)
    expect(File.exist?(servers.directory)).to be(false)
  end

  it "cleans up remaining servers when a child has already exited and been reaped", :aggregate_failures do
    exited_pid, = start_server("exited")
    running_pid, = start_server("running")
    Process.kill("KILL", exited_pid)
    Process.waitpid(exited_pid)

    servers.close

    expect { Process.waitpid(running_pid, Process::WNOHANG) }.to raise_error(Errno::ECHILD)
    expect(File.exist?(servers.directory)).to be(false)
  end
end
