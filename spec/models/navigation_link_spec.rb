require "rails_helper"

RSpec.describe NavigationLink do
  let(:navigation_link) { create(:navigation_link) }

  describe ".create_or_update_by_identity" do
    let(:attributes) { attributes_for(:navigation_link).except(:url, :id, :name).stringify_keys }
    let(:name) { navigation_link.name }

    # I want an existing navigation link, but don't want to apply the `let!` to the declaration as
    # that impacts tests in other describe blocks.
    before { navigation_link }

    context "when the url already exists" do
      let(:url) { navigation_link.url }

      it "updates the existing NavigationLink" do
        expect do
          described_class.create_or_update_by_identity(url: url, name: name, **attributes.symbolize_keys)
        end.not_to change(described_class, :count)

        expect(navigation_link.reload.attributes.slice(*attributes.keys)).to eq(attributes)
      end
    end

    context "when the url does not exist" do
      # Creating a different URL
      let(:url) { "#{navigation_link.url}-404" }

      it "creates a new NavigationLink" do
        expect do
          described_class.create_or_update_by_identity(url: url, name: name, **attributes)
        end.to change(described_class, :count).by(1)
      end
    end
  end

  describe "validations" do
    describe "presence validations" do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_presence_of(:url) }
      it { is_expected.to validate_presence_of(:icon) }
    end

    it "validates the icon" do
      navigation_link.icon = "test.png"
      expect(navigation_link).not_to be_valid

      navigation_link.icon = "<svg foo='bar'>"
      expect(navigation_link).to be_valid

      navigation_link.icon = "<svg foo='bar'\nbaz='lol'\n\n more stuff...\n\n.  >"
      expect(navigation_link).to be_valid
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
