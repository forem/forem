require "rails_helper"

RSpec.describe Images::GenerateSocialImage, type: :labor do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  it "returns the social image url if there is a social image" do
    article.social_image = Faker::Avatar.image
    expect(described_class.call(article)).to eq(article.social_image)
  end

  it "returns the main image if there is a main image" do
    article.main_image = Faker::Avatar.image
    article.social_image = nil
    expect(described_class.call(article)).to eq(article.main_image)
  end

  it "returns article social image" do
    article.main_image = nil
    article.social_image = nil
    article.cached_tag_list = "discuss, hello, goodbye"
    expect(described_class.call(article)).to include(
      "article/#{article.id}",
      "image/url2png",
      "c_fill,g_north,h_400,w_800/",
    )
  end

  it "creates various generated images of different title lengths" do
    [25, 49, 79, 99, 105].each do |n|
      article.assign_attributes(title: "0" * n, main_image: nil, cached_tag_list: "discuss, hello")
      expect(described_class.call(article).include?(article.title)).to eq(true)
    end
  end
end
