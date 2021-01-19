require "rails_helper"

RSpec.describe NavigationLink, type: :model do
  let(:navigation_link) { create(:navigation_link) }

  describe "validations" do
    describe "presence validations" do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_presence_of(:url) }
      it { is_expected.to validate_presence_of(:icon) }
    end

    it "validates the icon" do
      navigation_link.icon = "test.png"
      expect(navigation_link).not_to be_valid
    end

    context "when validating the URL" do
      it "does not allow invalid URLs" do
        navigation_link.url = "test"
        expect(navigation_link).not_to be_valid
      end

      it "does allow relative URLs" do
        navigation_link.url = "/test"
        expect(navigation_link).to be_valid
      end
    end
  end

  describe "callbacks" do
    let(:base_url) { "https://testforem.com" }

    before { allow(URL).to receive(:url).and_return(base_url) }

    it "normalizes local URLs to relative URLs on save" do
      navigation_link.url = "#{base_url}/test"
      navigation_link.save
      expect(navigation_link.url).to eq "/test"
    end

    it "persists relative URLs unchanged" do
      navigation_link.url = "/test"
      navigation_link.save
      expect(navigation_link.url).to eq "/test"
    end

    it "persists external URLs unchanged" do
      url = "https://example.com/test"
      navigation_link.url = url
      navigation_link.save
      expect(navigation_link.url).to eq url
    end
  end
end
