require "rails_helper"

RSpec.describe Trackable::Registry do
  before { described_class.reset! }
  after  { described_class.reset! }

  let(:dummy_adapter_class) do
    Class.new(Trackers::Base) do
      def track(event_name:, user_ids:, properties:, timestamp: nil); end
    end
  end

  let(:disabled_adapter_class) do
    Class.new(Trackers::Base) do
      def track(event_name:, user_ids:, properties:, timestamp: nil); end
      def enabled?; false; end
    end
  end

  describe ".register and .lookup" do
    it "stores and retrieves an adapter class by name" do
      described_class.register(:dummy, dummy_adapter_class)
      expect(described_class.lookup(:dummy)).to eq(dummy_adapter_class)
    end

    it "accepts string or symbol names" do
      described_class.register("dummy", dummy_adapter_class)
      expect(described_class.lookup(:dummy)).to eq(dummy_adapter_class)
    end

    it "returns nil for unknown names" do
      expect(described_class.lookup(:unknown)).to be_nil
    end
  end

  describe ".active" do
    before do
      described_class.register(:dummy, dummy_adapter_class)
      described_class.register(:disabled, disabled_adapter_class)
    end

    it "returns instances for adapters listed in TRACKABLE_ADAPTERS" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("TRACKABLE_ADAPTERS").and_return("dummy")

      expect(described_class.active.map(&:class)).to eq([dummy_adapter_class])
    end

    it "filters out adapters whose #enabled? returns false" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("TRACKABLE_ADAPTERS").and_return("dummy,disabled")

      expect(described_class.active.map(&:class)).to eq([dummy_adapter_class])
    end

    it "ignores unknown adapter names" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("TRACKABLE_ADAPTERS").and_return("dummy,nope")

      expect(described_class.active.map(&:class)).to eq([dummy_adapter_class])
    end

    it "memoizes instances across calls" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("TRACKABLE_ADAPTERS").and_return("dummy")

      expect(described_class.active.first).to be(described_class.active.first)
    end

    it "returns empty array when TRACKABLE_ADAPTERS is unset" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("TRACKABLE_ADAPTERS").and_return(nil)

      expect(described_class.active).to eq([])
    end
  end

  describe ".instance_for" do
    before { described_class.register(:dummy, dummy_adapter_class) }

    it "returns the same memoized instance as #active" do
      first = described_class.instance_for(:dummy)
      expect(first).to be_a(dummy_adapter_class)
      expect(described_class.instance_for(:dummy)).to be(first)
    end

    it "returns nil for unknown names" do
      expect(described_class.instance_for(:nope)).to be_nil
    end
  end
end
