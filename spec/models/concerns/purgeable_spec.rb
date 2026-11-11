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

  before do
    allow(EdgeCache::PurgeByKey).to receive(:call)
  end

  describe "class methods" do
    it "delegates purge_all to EdgeCache::PurgeByKey with table_key" do
      model_class.purge_all

      expect(EdgeCache::PurgeByKey).to have_received(:call).with("purgeables")
    end

    it "delegates soft_purge_all to EdgeCache::PurgeByKey with soft: true" do
      model_class.soft_purge_all

      expect(EdgeCache::PurgeByKey).to have_received(:call).with("purgeables", soft: true)
    end

    it "returns table_name with table_key" do
      expect(model_class.table_key).to eq(model_class.table_name)
    end

    it "short-circuits in development environment", :aggregate_failures do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))

      model_class.purge_all
      model_class.soft_purge_all

      expect(EdgeCache::PurgeByKey).not_to have_received(:call)
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

    it "delegates purge to EdgeCache::PurgeByKey with record_key" do
      purgeable_model.purge

      expect(EdgeCache::PurgeByKey).to have_received(:call).with("purgeables/1")
    end

    it "delegates soft_purge to EdgeCache::PurgeByKey with soft: true" do
      purgeable_model.soft_purge

      expect(EdgeCache::PurgeByKey).to have_received(:call).with("purgeables/1", soft: true)
    end

    it "short-circuits instance purges in development environment", :aggregate_failures do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))

      purgeable_model.purge
      purgeable_model.soft_purge

      expect(EdgeCache::PurgeByKey).not_to have_received(:call)
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
  end
end
