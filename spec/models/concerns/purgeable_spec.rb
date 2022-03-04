require "rails_helper"

class PurgeableModel
  include Purgeable

  def self.table_name
    "purgeables"
  end

  def id
    1
  end
end

RSpec.describe Purgeable do
  let(:model_class) { PurgeableModel }
  let(:purgeable_model) { model_class.new }
  let(:fastly_service) { instance_double(Fastly::Service) }

  before do
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("fake-key")
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return("fake-service-id")
    allow(Fastly::Service).to receive(:new).and_return(fastly_service)
  end

  describe "class methods" do
    it "calls .purge_by_key with table_key in purge_all" do
      allow(fastly_service).to receive(:purge_by_key)
      model_class.purge_all
      expect(fastly_service).to have_received(:purge_by_key).with(model_class.table_key)
    end

    it "calls .purge_by_key with table_key and true in soft_purge_all" do
      allow(fastly_service).to receive(:purge_by_key)
      model_class.soft_purge_all
      expect(fastly_service).to have_received(:purge_by_key).with(model_class.table_key, true)
    end

    it "returns table_name with table_key" do
      expect(model_class.table_key).to eq(model_class.table_name)
    end

    it "returns a Fastly object" do
      fastly = instance_double(Fastly)
      allow(Fastly).to receive(:new).and_return(fastly)
      model_class.fastly
      expect(Fastly).to have_received(:new)
    end

    it "returns a Fastly::Service object" do
      model_class.service
      expect(Fastly::Service).to have_received(:new)
    end
  end

  describe "instance methods" do
    it "returns a record key" do
      expect(purgeable_model.record_key).to eq("purgeables/1")
    end

    it "returns a table_key" do
      allow(model_class).to receive(:table_key).and_return(model_class.table_name)
      expect(purgeable_model.table_key).to eq(model_class.table_name)
      expect(model_class).to have_received(:table_key)
    end

    it "calls .purge_by_key with record_key in purge" do
      allow(fastly_service).to receive(:purge_by_key)
      purgeable_model.purge
      expect(fastly_service).to have_received(:purge_by_key).with(purgeable_model.record_key)
    end

    it "calls .purge_by_key with record_key and true in soft_purge" do
      allow(fastly_service).to receive(:purge_by_key)
      purgeable_model.soft_purge
      expect(fastly_service).to have_received(:purge_by_key).with(purgeable_model.record_key, true)
    end

    it "calls purge_all class method" do
      allow(model_class).to receive(:purge_all)
      purgeable_model.purge_all
      expect(model_class).to have_received(:purge_all)
    end

    it "calls soft_purge_all class method" do
      allow(model_class).to receive(:soft_purge_all)
      purgeable_model.soft_purge_all
      expect(model_class).to have_received(:soft_purge_all)
    end

    it "calls the fastly class method" do
      allow(model_class).to receive(:fastly)
      purgeable_model.fastly
      expect(model_class).to have_received(:fastly)
    end

    it "calls the service class method" do
      allow(model_class).to receive(:service)
      purgeable_model.service
      expect(model_class).to have_received(:service)
    end
  end
end
