# spec/lib/multi_store_cache_spec.rb
require 'rails_helper'
require 'multi_store_cache'

RSpec.describe MultiStoreCache do
  let(:primary_store) { instance_double(ActiveSupport::Cache::Store) }
  let(:secondary_store) { instance_double(ActiveSupport::Cache::Store) }
  let(:multi_store_cache) { described_class.new(primary_store, secondary_store) }

  let(:key) { "test_key" }
  let(:value) { "test_value" }
  let(:options) { { expires_in: 60.seconds } }

  describe "#read" do
    it "reads from the primary store only" do
      expect(primary_store).to receive(:read).with(key, nil).and_return(value)
      expect(secondary_store).not_to receive(:read)

      result = multi_store_cache.read(key)
      expect(result).to eq(value)
    end
  end

  describe "#write" do
    it "writes to both primary and secondary stores" do
      expect(primary_store).to receive(:write).with(key, value, nil)
      expect(secondary_store).to receive(:write).with(key, value, nil)

      multi_store_cache.write(key, value)
    end

    it "writes to both stores with options" do
      expect(primary_store).to receive(:write).with(key, value, options)
      expect(secondary_store).to receive(:write).with(key, value, options)

      multi_store_cache.write(key, value, options)
    end
  end

  describe "#delete" do
    it "deletes from both primary and secondary stores" do
      expect(primary_store).to receive(:delete).with(key, nil)
      expect(secondary_store).to receive(:delete).with(key, nil)

      multi_store_cache.delete(key)
    end
  end

  describe "#clear" do
    it "clears both primary and secondary stores" do
      expect(primary_store).to receive(:clear).with(nil)
      expect(secondary_store).to receive(:clear).with(nil)

      multi_store_cache.clear
    end
  end
end
