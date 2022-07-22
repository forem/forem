require "rails_helper"

describe SocialImageHelper do
  let(:user) { create(:user) }
  let(:article) { create(:article, main_image: nil) }

  describe ".article_social_image_url" do
    it "returns social preview path for newer articles" do
      allow(Settings::General).to receive(:app_domain).and_return("hello.com")
      url = helper.article_social_image_url(article)

      expect(url).to eq article_social_preview_url(article, format: :png, host: "hello.com")
    end

    it "returns the main image if set", cloudinary: true do
      article.main_image = Faker::CryptoCoin.url_logo

      url = helper.article_social_image_url(article)

      expect(url).to match(/#{article.main_image}/)
      expect(url).to include("c_imagga_scale,f_auto,fl_progressive,h_500,q_auto,w_1000/")
    end

    it "returns older url2png image if already generated" do
      article.updated_at = Articles::SocialImage::SOCIAL_PREVIEW_MIGRATION_DATETIME - 1.week

      url = helper.article_social_image_url(article)

      expect(url).to eq Images::GenerateSocialImage.call(article)
    end

    it "returns social preview path for newer decorated articles" do
      allow(Settings::General).to receive(:app_domain).and_return("hello.com")
      url = helper.article_social_image_url(article.decorate)

      expect(url).to eq article_social_preview_url(article, format: :png, host: "hello.com")
    end

    it "returns correct manipulation of cloudinary links", cloudinary: true do
      article.update_column(
        :main_image,
        "https://res.cloudinary.com/practicaldev/image/fetch/s--A-gun7rr--/c_imagga_scale,f_auto,fl_progressive,h_420,q_auto,w_1000/https://res.cloudinary.com/practicaldev/image/fetch/s--hcD8ZkbP--/c_imagga_scale%2Cf_auto%2Cfl_progressive%2Ch_420%2Cq_auto%2Cw_1000/https://dev-to-uploads.s3.amazonaws.com/i/th93d625o27nuz63oeen.png", # rubocop:disable Layout/LineLength
      )
      url = helper.article_social_image_url(article.decorate, width: 1600, height: 900)

      expect(url.scan(/res.cloudinary.com/).length).to be 1
      expect(url.scan(/w_1600/).length).to be 1
      expect(url.scan(/w_1000/).length).to be 0
    end
  end
end
