require "rails_helper"
require "sidekiq/sidekiq_connection_cleanup"

RSpec.describe Sidekiq::SidekiqConnectionCleanup do
  let(:middleware) { described_class.new }
  let(:worker) { double("worker") }
  let(:job) { { "class" => "SomeWorker" } }
  let(:queue) { "default" }

  describe "#call" do
    it "yields to the block" do
      expect { |b| middleware.call(worker, job, queue, &b) }.to yield_control
    end

    it "clears active connections after execution" do
      expect(ActiveRecord::Base.connection_handler).to receive(:clear_active_connections!).and_call_original
      middleware.call(worker, job, queue) {}
    end

    context "when open transactions are positive" do
      let(:conn) { ActiveRecord::Base.connection }

      before do
        allow(ActiveRecord::Base).to receive(:connection).and_return(conn)
        allow(conn).to receive(:open_transactions).and_return(1)
        allow(ActiveRecord::Base.connection_handler).to receive(:clear_active_connections!).and_call_original
      end

      it "rolls back the transaction" do
        expect(conn).to receive(:rollback_db_transaction)
        middleware.call(worker, job, queue) {}
      end

      it "logs a warning and continues if rollback fails" do
        allow(conn).to receive(:rollback_db_transaction).and_raise(StandardError, "rollback error")
        expect(::Rails.logger).to receive(:warn).with(/Sidekiq ConnectionCleanup: rollback failed: StandardError: rollback error/)
        middleware.call(worker, job, queue) {}
      end
    end
  end
end
