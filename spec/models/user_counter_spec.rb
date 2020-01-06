require "rails_helper"

RSpec.describe UserCounter, type: :model do
  let(:counters) { build(:user_counter) }

  describe "validations" do
    describe "builtin validations" do
      subject { build(:user_counter, user: create(:user)) }

      it { is_expected.to belong_to(:user) }
      it { is_expected.to validate_presence_of(:user) }
      it { is_expected.to validate_uniqueness_of(:user) }
    end

    describe "#comments_these_7_days" do
      it "is valid if comments_these_7_days is an integer" do
        counters.comments_these_7_days = 1
        expect(counters).to be_valid
      end

      it "is is not if comments_these_7_days is not an integer" do
        counters.comments_these_7_days = 1.2
        expect(counters).not_to be_valid
      end
    end

    describe "#comments_prior_7_days" do
      it "is valid if comments_prior_7_days is an integer" do
        counters.comments_prior_7_days = 1
        expect(counters).to be_valid
      end

      it "is is not if comments_prior_7_days is not an integer" do
        counters.comments_prior_7_days = 1.2
        expect(counters).not_to be_valid
      end
    end
  end
end
