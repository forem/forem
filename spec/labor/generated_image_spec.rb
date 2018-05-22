require 'rails_helper'

RSpec.describe GeneratedImage do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  it 'should return the social image url if there is a social image' do
    article.social_image = Faker::Avatar.image
    expect(GeneratedImage.new(article).social_image).to eq(article.social_image)
  end

  it 'should return the main image if there is a main image' do
    article.main_image = Faker::Avatar.image
    article.social_image = nil
    expect(GeneratedImage.new(article).social_image).to eq(article.main_image)
  end

  it 'should return article social image' do
    article.main_image = nil
    article.social_image = nil
    article.cached_tag_list = "discuss, hello, goodbye"
    expect(GeneratedImage.new(article).social_image.include? "article/#{article.id}").to eq(true)
  end

  it "creates various generated images of different title lengths" do
    nums = [25,49,79,99,105]
    nums.each do |n|
      article.title = "0" * n
      article.cached_tag_list = "discuss, hello, goodbye"
      GeneratedImage.new(article).social_image
      article.cached_tag_list = "hello, goodbye"
      GeneratedImage.new(article).social_image
    end
  end
end
