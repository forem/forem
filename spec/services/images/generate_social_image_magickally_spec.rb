require "rails_helper"

RSpec.describe Images::GenerateSocialImageMagickally, type: :model do
  let(:user) { create(:user) }
  let!(:article) { create(:article, user_id: user.id, with_main_image: false) }
  let(:organization) { create(:organization) }
  let!(:second_article) { create(:article, user_id: user.id, organization_id: organization.id, with_main_image: false) }

  describe ".call" do
    context "when resource is an Article" do
      let(:generator) { described_class.new(article) }

      before do
        allow(described_class).to receive(:new).and_return(generator)
        allow(generator).to receive(:read_files)
      end

      it "calls the class methods" do
        expect(generator).to receive(:generate_magickally).once
        described_class.call(article)
      end

      it "updates article to have social image" do
        expect(generator).to receive(:generate_magickally).and_return("https://www.example.com")
        described_class.call(article)
        expect(article.reload.social_image).to eq("https://www.example.com")
      end
    end

    context "when resource is a User" do
      let(:generator) { described_class.new(user) }

      before do
        allow(described_class).to receive(:new).and_return(generator)
        allow(generator).to receive(:read_files)
      end

      it "calls the class methods for each published article" do
        expect(generator).to receive(:generate_magickally).once
          .with(
            title: article.title,
            date: article.readable_publish_date,
            author_name: user.name,
            color: user.setting.brand_color1
          )
        described_class.call(user)
      end

      it "updates article to have social image" do
        expect(generator).to receive(:generate_magickally).and_return("https://www.example.com")
        described_class.call(user)
        expect(article.reload.social_image).to eq("https://www.example.com")
      end
    end

    context "when resource is an Organization" do
      let(:generator) { described_class.new(organization) }

      before do
        allow(described_class).to receive(:new).and_return(generator)
        allow(generator).to receive(:read_files)
      end

      it "calls the class methods for each published article" do
        expect(generator).to receive(:generate_magickally).once
          .with(
            title: second_article.title,
            date: second_article.readable_publish_date,
            author_name: organization.name,
            color: organization.bg_color_hex
          )
        described_class.call(organization)
      end

      it "updates article to have social image" do
        expect(generator).to receive(:generate_magickally).and_return("https://www.example.com")
        described_class.call(organization)
        expect(second_article.reload.social_image).to eq("https://www.example.com")
      end
    end
  end
end
