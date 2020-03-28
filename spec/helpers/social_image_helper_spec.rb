require "rails_helper"

describe SocialImageHelper do
  let(:user) { create(:user) }
  let(:article) { create(:article, main_image: nil) }

  describe ".user_social_image_url" do
    it "returns social preview path for newer users" do
      url = helper.user_social_image_url(user)

      expect(url).to eq user_social_preview_url(user, format: :png)
    end

    it "returns Organization social preview path for Orgs" do
      organization = create(:organization)

      url = helper.user_social_image_url(organization)

      expect(url).to eq organization_social_preview_url(organization, format: :png)
    end

    it "returns older url2png image if already generated" do
      user.updated_at = SocialImageHelper::SOCIAL_PREVIEW_MIGRATION_DATETIME - 1.week

      url = helper.user_social_image_url(user)

      expect(url).to eq GeneratedImage.new(user).social_image
    end

    it "returns social preview path for newer decorated users" do
      url = helper.user_social_image_url(user.decorate)

      expect(url).to eq user_social_preview_url(user, format: :png)
    end
  end

  describe ".article_social_image_url" do
    it "returns social preview path for newer articles" do
      url = helper.article_social_image_url(article)

      expect(url).to eq article_social_preview_url(article, format: :png)
    end

    it "returns the main image if set" do
      article.main_image = Faker::CryptoCoin.url_logo

      url = helper.article_social_image_url(article)

      expect(url).to match(/#{article.main_image}/)
    end

    it "returns older url2png image if already generated" do
      article.updated_at = SocialImageHelper::SOCIAL_PREVIEW_MIGRATION_DATETIME - 1.week

      url = helper.article_social_image_url(article)

      expect(url).to eq GeneratedImage.new(article).social_image
    end

    it "returns social preview path for newer decorated articles" do
      url = helper.article_social_image_url(article.decorate)

      expect(url).to eq article_social_preview_url(article, format: :png)
    end
  end
end
