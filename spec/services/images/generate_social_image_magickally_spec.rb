require "rails_helper"

RSpec.describe Images::GenerateSocialImageMagickally, type: :model do
  let(:user) { create(:user) }
  let!(:article) { create(:article, user_id: user.id) }
  let(:organization) { create(:organization) }
  let!(:second_article) { create(:article, user_id: user.id, organization_id: organization.id) }

  describe ".call" do
    before do
      expect_any_instance_of(described_class).to receive(:read_files).once
    end
    context "when resource is an Article" do
      it "calls the class methods" do
        expect_any_instance_of(described_class).to receive(:generate_magickally).once
        described_class.call(article)
      end
      
      it "updates article to have social image" do
        expect_any_instance_of(described_class).to receive(:generate_magickally).and_return("https://www.example.com")
        described_class.call(article)
        expect(article.reload.social_image).to eq("https://www.example.com")
      end
    end

    context "when resource is a User" do
      it "calls the class methods for each published article" do
        expect_any_instance_of(described_class).to receive(:generate_magickally).once
          .with(
            title: article.title,
            date: article.readable_publish_date,
            author_name: user.name,
            color: user.setting.brand_color1
          )
        described_class.call(user)
      end
      it "updates article to have social image" do
        expect_any_instance_of(described_class).to receive(:generate_magickally).and_return("https://www.example.com")
        described_class.call(user)
        expect(article.reload.social_image).to eq("https://www.example.com")
      end
    end

    context "when resource is an Organization" do
      it "calls the class methods for each published article" do
        expect_any_instance_of(described_class).to receive(:generate_magickally).once
          .with(
            title: second_article.title,
            date: second_article.readable_publish_date,
            author_name: organization.name,
            color: organization.bg_color_hex
          )
        described_class.call(organization)
      end
      it "updates article to have social image" do
        expect_any_instance_of(described_class).to receive(:generate_magickally).and_return("https://www.example.com")
        described_class.call(user)
        expect(article.reload.social_image).to eq("https://www.example.com")
      end
    end
  end
end
