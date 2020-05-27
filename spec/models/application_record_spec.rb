require "rails_helper"

# ApplicationRecord is an abstract class, tests will use one of the core models
RSpec.describe ApplicationRecord, type: :model do
  describe ".estimated_count" do
    xit "does not raise errors if there are no rows" do
      expect { User.estimated_count }.not_to raise_error
    end
  end

  describe "#decorate" do
    xit "decorates an object that has a decorator" do
      sponsorship = build(:sponsorship)
      expect(sponsorship.decorate).to be_a(SponsorshipDecorator)
    end

    xit "raises an error if an object has no decorator" do
      badge = build(:badge)
      expect { badge.decorate }.to raise_error(UninferrableDecoratorError)
    end
  end

  describe "#decorated?" do
    xit "returns false" do
      sponsorship = build(:sponsorship)
      expect(sponsorship.decorated?).to be(false)
    end
  end

  describe ".decorate" do
    before do
      create(:sponsorship, level: :gold)
    end

    xit "decorates a relation" do
      decorated_collection = Sponsorship.gold.decorate
      expect(decorated_collection.size).to eq(Sponsorship.gold.size)
      expect(decorated_collection.first).to be_a(SponsorshipDecorator)
    end
  end
end
