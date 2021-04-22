require "rails_helper"

RSpec.describe Homepage::FetchArticles, type: :service do
  describe ".call" do
    # rubocop:disable RSpec/ExampleLength
    it "returns results in the correct format", :aggregate_failures do
      article = create(
        :article, video_thumbnail_url: "https://example.com", tags: Constants::Tags::FLARE_TAG_NAMES.first
      )
      create(:comment, commentable: article)

      result = described_class.call.first

      keys = %i[
        class_name cloudinary_video_url comments_count id path public_reactions_count
        published_at_int readable_publish_date reading_time tag_flare tag_list title
        user user_id video_duration_string
      ]
      expect(result.keys.sort).to eq(keys)

      expect(result[:class_name]).to eq("Article")
      expect(result[:cloudinary_video_url]).to eq(article.cloudinary_video_url)
      expect(result[:comments_count]).to eq(article.comments.size)
      expect(result[:id]).to eq(article.id)
      expect(result[:path]).to eq(article.path)
      expect(result[:public_reactions_count]).to eq(article.public_reactions_count)

      expect(result[:published_at_int]).to eq(article.published_at.to_i)
      expect(result[:readable_publish_date]).to eq(article.readable_publish_date)
      expect(result[:reading_time]).to eq(article.reading_time)
      expect(result[:tag_flare]).to eq(Homepage::FetchTagFlares.call([article])[article.id])
      expect(result[:tag_list]).to eq(article.tag_list)
      expect(result[:title]).to eq(article.title)

      expect(result[:user_id]).to eq(article.user_id)
      expect(result[:video_duration_string]).to eq(article.video_duration_in_minutes)
    end
    # rubocop:enable RSpec/ExampleLength

    it "returns the user object in the correct format", :aggregate_failures do
      article = create(:article)

      result = described_class.call.first
      user = result[:user]

      expect(user[:name]).to eq(article.user.name)
      expect(user[:profile_image_90]).to eq(article.user.profile_image_90)
      expect(user[:username]).to eq(article.user.username)
    end

    it "returns the organization object in the correct format", :aggregate_failures do
      article = create(:article, organization: create(:organization))

      result = described_class.call.first
      organization = result[:organization]

      expect(organization[:name]).to eq(article.organization.name)
      expect(organization[:profile_image_90]).to eq(article.organization.profile_image_90)
      expect(organization[:slug]).to eq(article.organization.slug)
    end
  end
end
