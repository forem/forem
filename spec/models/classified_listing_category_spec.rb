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

    context "when validating social preview colors" do
      let(:category) { build(:classified_listing_category) }

      xit "rejects invalid formats" do
        category.social_preview_color = "#DEV.TO"
        category.validate

        expect(category.errors[:social_preview_color]).to eq(["is invalid"])
      end

      xit "normalizes the input to lowercase before validation" do
        category.social_preview_color = "#CCCCCC"
        category.validate

        expect(category.social_preview_color).to eq("#cccccc")
      end

      xit "accepts missing social preview colors" do
        category.social_preview_color = nil
        category.validate

        expect(category).to be_valid
      end
    end
  end
end
