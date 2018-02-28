require "rails_helper"

RSpec.describe Organization, type: :model do
  let(:user)         { create(:user) }
  let(:organization) { create(:organization) }

  describe "#name" do
    it "rejects names with over 50 characters" do
      organization.name = Faker::Lorem.characters(51)
      expect(organization).not_to be_valid
    end

    it "accepts names with 50 or less characters" do
      expect(organization).to be_valid
    end
  end

  describe "#summary" do
    it "rejects summaries with over 1000 characters" do
      organization.summary = Faker::Lorem.characters(1001)
      expect(organization).not_to be_valid
    end

    it "accepts summaries with 1000 or less characters" do
      expect(organization).to be_valid
    end
  end

  describe "#text_color_hex" do
    it "accepts hex color codes" do
      organization.text_color_hex = Faker::Color.hex_color
      expect(organization).to be_valid
    end

    it "rejects color names" do
      organization.text_color_hex = Faker::Color.color_name
      expect(organization).not_to be_valid
    end

    it "rejects RGB colors" do
      organization.text_color_hex = Faker::Color.rgb_color
      expect(organization).not_to be_valid
    end

    it "rejects wrong color format" do
      organization.text_color_hex = "##{Faker::Lorem.words(4)}"
      expect(organization).not_to be_valid
    end
  end

  describe "#slug" do
    it "accepts properly formatted slug" do
      organization.slug = "heyho"
      expect(organization).to be_valid
    end

    it "accepts properly formatted slug with numbers" do
      organization.slug = "HeyHo2"
      expect(organization).to be_valid
    end

    it "rejects slug with spaces" do
      organization.slug = "hey ho"
      expect(organization).not_to be_valid
    end

    it "rejects slug with unacceptable character" do
      organization.slug = "Hey&Ho"
      expect(organization).not_to be_valid
    end

    it "downcases slug" do
      organization.slug = "HaHaHa"
      organization.save
      expect(organization.slug).to eq("hahaha")
    end
  end

  describe "#url" do
    it "accepts valid http url" do
      organization.url = "http://ben.com"
      expect(organization).to be_valid
    end

    it "accepts valid secure http url" do
      organization.url = "https://ben.com"
      expect(organization).to be_valid
    end

    it "rejects invalid http url" do
      organization.url = "ben.com"
      expect(organization).not_to be_valid
    end
  end
end
