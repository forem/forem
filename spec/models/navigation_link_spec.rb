require "rails_helper"

RSpec.describe NavigationLink, type: :model do
  describe "validations" do
    describe "presence validations" do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_presence_of(:url) }
      it { is_expected.to validate_presence_of(:icon) }
    end

    describe "regex validations" do
      let(:navigation_link) { create(:navigation_link) }

      it "vaidates the url" do
        navigation_link.url = "test"
        expect(navigation_link).not_to be_valid
      end

      it "vaidates the icon" do
        navigation_link.icon = "test.png"
        expect(navigation_link).not_to be_valid
      end
    end
  end
end
