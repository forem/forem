require "rails_helper"

# ApplicationRecord is an abstract class, tests will use one of the core models
RSpec.describe ApplicationRecord, type: :model do
  describe ".estimated_count" do
    it "does not raise errors if there are no rows" do
      expect { User.estimated_count }.not_to raise_error
    end
  end

  describe ".decorate_" do
    it "decorates an object that has a decorator" do
      sponsorship = build(:sponsorship)
      expect(sponsorship.decorate_).to be_a(SponsorshipDecorator)
    end

    it "raises an error if an object has no decorator" do
      badge = build(:badge)
      expect { badge.decorate_ }.to raise_error(UninferrableDecoratorError)
    end
  end
end
