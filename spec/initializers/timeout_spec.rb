# rubocop:disable RSpec/FilePath, RSpec/SpecFilePathFormat
require "rails_helper"

RSpec.describe Rack::Timeout, type: :initializer do
  describe "clear_db_connections_on_timeout state change observer" do
    let(:env) { {} }
    let(:state_info) { instance_double(described_class::RequestDetails, state: state) }

    before do
      env[described_class::ENV_INFO_KEY] = state_info
    end

    context "when state is :timed_out" do
      let(:state) { :timed_out }

      it "disconnects and clears active connections" do
        allow(ActiveRecord::Base.connection_pool).to receive(:active_connection?).and_return(true)
        real_connection = ActiveRecord::Base.connection_pool.connection
        allow(real_connection).to receive(:disconnect!)
        allow(ActiveRecord::Base).to receive(:clear_active_connections!).and_call_original

        # Retrieve the observer proc directly from the registry
        observers = described_class.instance_variable_get(:@state_change_observers)
        observer_proc = observers[:clear_db_connections_on_timeout]
        expect(observer_proc).not_to be_nil

        observer_proc.call(env)

        expect(real_connection).to have_received(:disconnect!)
        expect(ActiveRecord::Base).to have_received(:clear_active_connections!)
      end
    end

    context "when state is other than timed_out" do
      let(:state) { :ready }

      it "does not clear connections" do
        allow(ActiveRecord::Base.connection_pool).to receive(:active_connection?).and_call_original
        allow(ActiveRecord::Base).to receive(:clear_active_connections!).and_call_original

        observers = described_class.instance_variable_get(:@state_change_observers)
        observer_proc = observers[:clear_db_connections_on_timeout]
        expect(observer_proc).not_to be_nil

        observer_proc.call(env)

        expect(ActiveRecord::Base.connection_pool).not_to have_received(:active_connection?)
        expect(ActiveRecord::Base).not_to have_received(:clear_active_connections!)
      end
    end
  end
end
# rubocop:enable RSpec/FilePath, RSpec/SpecFilePathFormat
