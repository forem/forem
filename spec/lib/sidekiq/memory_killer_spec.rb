require "rails_helper"
require "sidekiq/memory_killer"

RSpec.describe Sidekiq::MemoryKiller do
  let(:middleware) { described_class.new }
  let(:worker) { double("worker") }
  let(:job) { { "class" => "SomeWorker" } }
  let(:queue) { "default" }
  let(:yield_block) { -> {} }

  before do
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
        expect(middleware).not_to receive(:check_and_kill!)
        middleware.call(worker, job, queue, &yield_block)
      end
    end

    context "when enabled via ENV" do
      before do
        stub_const("ENV", ENV.to_hash.merge("SIDEKIQ_MEMORY_KILLER_ENABLED" => "true", "SIDEKIQ_MEMORY_KILLER_MAX_MB" => "1024"))
      end

      it "checks memory" do
        expect(middleware).to receive(:extract_memory_kb).and_return(500000)
        middleware.call(worker, job, queue, &yield_block)
      end

      context "when memory is below the limit" do
        before do
          # Return ~500 MB
          allow(middleware).to receive(:extract_memory_kb).and_return(512000)
        end

        it "does not kill the process" do
          expect(Process).not_to receive(:kill)
          middleware.call(worker, job, queue, &yield_block)
        end
      end

      context "when memory exceeds the limit" do
        it "logs a warning and kills the process with SIGTERM" do
          expect(middleware).to receive(:extract_memory_kb).and_return(1536000)
          expect(::Rails.logger).to receive(:warn)
          expect(::Process).to receive(:kill).with("TERM", ::Process.pid)
          
          middleware.call(worker, job, queue, &yield_block)
        end
      end

      context "when the memory check raises an error" do
        before do
          allow(middleware).to receive(:extract_memory_kb).and_raise(StandardError, "ps command failed")
          allow(::Rails.logger).to receive(:error)
        end

        it "rescues the error, logs it, and does not crash the worker" do
          expect(::Rails.logger).to receive(:error).with(/SidekiqMemoryKiller: Failed to check memory: ps command failed/)
          expect { middleware.call(worker, job, queue, &yield_block) }.not_to raise_error
        end
      end
    end
  end
end
