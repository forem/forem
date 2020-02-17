require "rails_helper"

RSpec.describe ApplicationDecorator, type: :decorator do
  describe "#object" do
    it "exposes the decorated object" do
      obj = Object.new
      expect(described_class.new(obj).object).to be(obj)
    end
  end

  describe "#decorated?" do
    it "returns true" do
      obj = Object.new
      expect(described_class.new(obj).decorated?).to be(true)
    end
  end

  # as ApplicationDecorator is an abstract class, some tests also use an actual decorator
  describe ".decorate_collection" do
    before do
      create(:sponsorship, level: :gold)
    end

    it "receives an ActiveRecord relation and returns an array of decorated records" do
      relation = Sponsorship.gold

      decorated_collection = described_class.decorate_collection(relation)
      expect(decorated_collection.map(&:class)).to eq([SponsorshipDecorator])
      expect(decorated_collection.map(&:object)).to eq(relation.to_a)
    end

    it "receives an array and returns an array of decorated records" do
      relation = Sponsorship.gold

      decorated_collection = described_class.decorate_collection(relation.to_a)
      expect(decorated_collection.map(&:class)).to eq([SponsorshipDecorator])
      expect(decorated_collection.map(&:object)).to eq(relation.to_a)
    end
  end
end
