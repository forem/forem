require "rails_helper"

RSpec.describe ClassifiedListingCategory, type: :model do
  describe "validations" do
    # The uniqueness validation didn't work without this, see section "Caveat" at
    # https://www.rubydoc.info/github/thoughtbot/shoulda-matchers/Shoulda%2FMatchers%2FActiveRecord:validate_uniqueness_of
    subject { create(:classified_listing_category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:cost) }
    it { is_expected.to validate_presence_of(:rules) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_uniqueness_of(:slug) }
  end
end
