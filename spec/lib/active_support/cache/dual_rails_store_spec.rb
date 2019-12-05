require "rails_helper"

RSpec.describe ActiveSupport::Cache::DualRailsStore, type: :lib do
  subject do
    ActiveSupport::Cache.lookup_store :dual_rails_store,
                                      default_store: [
                                        :memory_store,
                                        { size: 10.megabytes },
                                      ],
                                      second_store: [
                                        :redis_store,
                                        { size: 5.megabytes, expires_in: 200 },
                                      ]
  end

  let(:dual_store) { subject }
  let(:default_store) { subject.stores.values.first }
  let(:second_store) { subject.stores.values.last }

  describe "#initialized" do
    it "does not raise an error" do
      expect { dual_store }.not_to raise_error
    end

    it "sets stores instance variable" do
      expect(dual_store.stores.count).to eq(2)
    end
  end

  describe "cache behavior" do
    it "can #write" do
      expect(dual_store.write("foo", "bar")).to be_truthy
    end

    it "can #read" do
      dual_store.write("foo", "bar")
      expect(dual_store.read("foo")).to eq("bar")
    end

    it "can #delete" do
      dual_store.write("foo", "bar")
      dual_store.delete("foo")
      expect(dual_store.read("foo")).to be_nil
    end

    it "can #fetch" do
      expect(dual_store.fetch("foo") { "bar" }).to eq("bar")
      expect(dual_store.fetch("foo") { "qux" }).to eq("bar")
    end

    it "honors expiration" do
      dual_store.write("foo", "bar", expires_in: 0)
      expect(dual_store.read("foo")).to be_nil
    end

    it "honors default expiration" do
      dual_store.write("foo", "bar", all: true)
      ttl = second_store.data.ttl("foo")
      expect(ttl).to be < 201
      expect(ttl).to be > 0
    end

    it "can #clear" do
      dual_store.write("foo", "bar")
      dual_store.clear
      expect(dual_store.read("foo")).to be_nil
    end

    it "raises an error for an unknown store" do
      expect { dual_store.write("foo", "bar", only: :foo) }.to raise_error("Store not found!")
    end
  end

  describe "storage" do
    it "writes to all stores with all option" do
      dual_store.write("foo", "bar", all: true)
      expect(default_store.read("foo")).to eq("bar")
      expect(second_store.read("foo")).to eq("bar")
    end

    it "reads from the default store" do
      default_store.write("foo", "bar1")
      second_store.write("foo", "bar2")
      expect(dual_store.read("foo")).to eq("bar1")
    end

    it "can read from the bottom store" do
      second_store.write("foo", "bar2")
      expect(dual_store.read("foo", only: :second_store)).to eq("bar2")
    end
  end

  describe ":only restrictions" do
    it "only writes to the selected store" do
      dual_store.write("foo", "bar", only: :second_store)
      expect(default_store.read("foo")).to be_nil
      expect(second_store.read("foo")).to eq("bar")
    end

    it "only reads the selected store" do
      default_store.write("foo", "bar1", only: :default_store)
      second_store.write("foo", "bar2", only: :second_store)
      expect(dual_store.read("foo", only: :default_store)).to eq("bar1")
      expect(dual_store.read("foo", only: :second_store)).to eq("bar2")
    end
  end

  describe "#read_multi" do
    before do
      dual_store.write("a", "a1", only: :default_store)
      dual_store.write("a", "a2", only: :second_store)
      dual_store.write("b", "b1", only: :default_store)
      dual_store.write("c", "c2", only: :second_store)
    end

    it "mass-reads data from each store" do
      expect(dual_store.read_multi("a", "b", "c", "d")).to eq("a" => "a1", "b" => "b1", "c" => "c2")
    end
  end
end
