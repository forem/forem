require "rails_helper"

RSpec.describe Search::Cluster, type: :service do
  describe "::recreate_indexes" do
    it "destroys and sets up indexes" do
      allow(described_class).to receive(:delete_indexes)
      allow(described_class).to receive(:setup_indexes)

      described_class.recreate_indexes
      expect(described_class).to have_received(:delete_indexes)
      expect(described_class).to have_received(:setup_indexes)
    end
  end

  describe "::setup_indexes" do
    it "creates, adds aliases and updates mappings for indexes" do
      allow(described_class).to receive(:create_indexes)
      allow(described_class).to receive(:add_aliases)
      allow(described_class).to receive(:update_mappings)

      described_class.setup_indexes
      expect(described_class).to have_received(:create_indexes)
      expect(described_class).to have_received(:add_aliases)
      expect(described_class).to have_received(:update_mappings)
    end
  end

  describe "::create_indexes" do
    it "calls create_index for each search class" do
      allow(Search::Client.indices).to receive(:exists).and_return(false)
      described_class::SEARCH_CLASSES.each do |search_class|
        allow(search_class).to receive(:create_index)
      end
      described_class.create_indexes
      expect(described_class::SEARCH_CLASSES).to all(have_received(:create_index))
    end
  end

  describe "::delete_indexes" do
    it "calls delete_index for each search class" do
      allow(Search::Client.indices).to receive(:exists).and_return(true)
      described_class::SEARCH_CLASSES.each do |search_class|
        allow(search_class).to receive(:delete_index)
      end
      described_class.delete_indexes
      expect(described_class::SEARCH_CLASSES).to all(have_received(:delete_index))
    end
  end

  describe "::add_aliases" do
    it "calls add_alias for each search class" do
      described_class::SEARCH_CLASSES.each do |search_class|
        allow(search_class).to receive(:add_alias)
      end
      described_class.add_aliases
      expect(described_class::SEARCH_CLASSES).to all(have_received(:add_alias))
    end
  end

  describe "::update_mappings" do
    it "calls update_mappings for each search class" do
      described_class::SEARCH_CLASSES.each do |search_class|
        allow(search_class).to receive(:update_mappings)
      end
      described_class.update_mappings
      expect(described_class::SEARCH_CLASSES).to all(have_received(:update_mappings))
    end
  end

  describe "::update_settings" do
    it "updates cluster settings" do
      described_class.update_settings
      cluster_settings = Search::Client.cluster.get_settings
      auto_create_setting = cluster_settings.dig("persistent", "action", "auto_create_index")
      expect(auto_create_setting).to eq("false")
    end
  end
end
