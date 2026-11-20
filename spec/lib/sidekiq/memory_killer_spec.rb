require "rails_helper"
require "sidekiq/memory_killer"

RSpec.describe Sidekiq::MemoryKiller do
  let(:middleware) { described_class.new }
  let(:worker) { Object.new }
  let(:job) { { "class" => "SomeWorker" } }
  let(:queue) { "default" }
  let(:yield_block) { -> {} }

  before do
    described_class.reset_state!
    allow(Process).to receive(:kill).with("TERM", Process.pid)
  end

  describe "#call" do
    it "yields to the block" do
      stub_const("ENV", ENV.to_hash.merge("SIDEKIQ_MEMORY_KILLER_ENABLED" => "false"))
      expect { |b| middleware.call(worker, job, queue, &b) }.to yield_control
    end

    context "when disabled via ENV" do
      before do
        stub_const("ENV", ENV.to_hash.merge("SIDEKIQ_MEMORY_KILLER_ENABLED" => "false"))
      end

      it "does not check memory" do
        allow(middleware).to receive(:check_and_kill!)
        middleware.call(worker, job, queue, &yield_block)
        expect(middleware).not_to have_received(:check_and_kill!)
      end
    end

    context "when enabled via ENV" do
      before do
        stub_const(
          "ENV",
          ENV.to_hash.merge(
            "SIDEKIQ_MEMORY_KILLER_ENABLED" => "true",
            "SIDEKIQ_MEMORY_KILLER_MAX_MB" => "1024",
            "SIDEKIQ_MEMORY_KILLER_CHECK_INTERVAL" => "0",
          ),
        )
      end

      it "checks memory" do
        allow(middleware).to receive(:extract_memory_kb).and_return(500_000)
        middleware.call(worker, job, queue, &yield_block)
        expect(middleware).to have_received(:extract_memory_kb)
      end

      it "does not kill the process when memory is below the limit" do
        allow(middleware).to receive(:extract_memory_kb).and_return(512_000)
        middleware.call(worker, job, queue, &yield_block)
        expect(Process).not_to have_received(:kill)
      end

      it "logs a warning and kills the process with SIGTERM when memory exceeds the limit" do
        allow(middleware).to receive(:extract_memory_kb).and_return(1_536_000)
        allow(Rails.logger).to receive(:warn)

        middleware.call(worker, job, queue, &yield_block)

        expect(Rails.logger).to have_received(:warn).with(/Memory usage 1500\.0MB \(RSS \+ Swap\) exceeds max 1024MB/)
        expect(Process).to have_received(:kill).with("TERM", Process.pid).once
      end

      it "only sends SIGTERM once across multiple middleware instances and threads" do
        first_instance = described_class.new
        second_instance = described_class.new
        allow(first_instance).to receive(:extract_memory_kb).and_return(1_536_000)
        allow(second_instance).to receive(:extract_memory_kb).and_return(1_536_000)
        allow(Rails.logger).to receive(:warn)

        first_instance.call(worker, job, queue, &yield_block)
        second_instance.call(worker, job, queue, &yield_block)

        expect(Process).to have_received(:kill).with("TERM", Process.pid).once
      end

      it "rescues the error, logs it, and does not crash the worker when the memory check raises an error" do
        allow(middleware).to receive(:extract_memory_kb).and_raise(StandardError, "ps command failed")
        allow(Rails.logger).to receive(:error)

        expect { middleware.call(worker, job, queue, &yield_block) }.not_to raise_error
        expect(Rails.logger).to have_received(:error)
          .with(/SidekiqMemoryKiller: Failed to check memory: ps command failed/)
      end
    end

    context "when /proc/self/status includes both VmRSS and VmSwap (Linux/Heroku cgroup)" do
      before do
        stub_const(
          "ENV",
          ENV.to_hash.merge(
            "SIDEKIQ_MEMORY_KILLER_ENABLED" => "true",
            "SIDEKIQ_MEMORY_KILLER_CHECK_INTERVAL" => "0",
          ),
        )
      end

      it "defaults max memory to 950MB and sums VmRSS + VmSwap to detect swap bloat on 1GB dynos" do
        proc_status = <<~STATUS
          Name:\truby
          Umask:\t0022
          State:\tS (sleeping)
          VmPeak:\t 2450000 kB
          VmSize:\t 2310000 kB
          VmRSS:\t  940000 kB
          RssAnon:\t  910000 kB
          VmSwap:\t  620000 kB
          Threads:\t21
        STATUS

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with("/proc/self/status").and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with("/proc/self/status").and_return(proc_status)
        allow(Rails.logger).to receive(:warn)

        # VmRSS alone is 940,000 KB (~918 MB, below 950 MB),
        # but VmRSS + VmSwap is 1,560,000 KB (~1523.44 MB, well above 950 MB).
        middleware.call(worker, job, queue, &yield_block)

        expect(Rails.logger).to have_received(:warn).with(/Memory usage 1523\.44MB \(RSS \+ Swap\) exceeds max 950MB/)
        expect(Process).to have_received(:kill).with("TERM", Process.pid).once
      end
    end

    context "when check interval throttling is active" do
      before do
        stub_const(
          "ENV",
          ENV.to_hash.merge(
            "SIDEKIQ_MEMORY_KILLER_ENABLED" => "true",
            "SIDEKIQ_MEMORY_KILLER_MAX_MB" => "950",
            "SIDEKIQ_MEMORY_KILLER_CHECK_INTERVAL" => "10",
          ),
        )
      end

      it "checks memory at most once within the configured interval" do
        allow(middleware).to receive(:extract_memory_kb).and_return(500_000)

        middleware.call(worker, job, queue, &yield_block)
        middleware.call(worker, job, queue, &yield_block)

        expect(middleware).to have_received(:extract_memory_kb).once
      end
    end
  end
end
