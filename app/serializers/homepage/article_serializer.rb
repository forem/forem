module Homepage
  class ArticleSerializer < ApplicationSerializer
    attributes(
      :class_name,
      :cloudinary_video_url,
      :comments_count,
      :id,
      :path,
      :public_reactions_count,
      :readable_publish_date,
      :reading_time,
      :title,
      :user_id,
    )

    attribute :video_duration_string, &:video_duration_in_minutes
    attribute :published_at_int, ->(article) { article.published_at.to_i }
    attribute :tag_list, ->(article) { article.cached_tag_list.to_s.split(", ") }
    attribute :flare_tag, ->(article, params) { params.dig(:tag_flares, article.id) }

    attribute :user do |article|
      user = article.user

      # Without the to_json we might not have properly escaped key/value pairs.
      #
      # [@jeremyf] I was running the ./cypress/integration/seededFlows/loginFlows/userLogout.spec.js
      #   and kept getting a rather erratic error.  The
      #   ./app/assets/javascripts/utilities/buildArticleHTML.js was generating unparsable JSON for
      #   the ./app/javascript/packs/followButtons.js.  The cypress test was GET-ting
      #   /search/feed_content, which called Homepage::ArticlesQuery which called
      #   Homepage::ArticleSerializer (this class).  When I added the `.to_json` this appeared to
      #   fix the breaking and somewhat erratic test.
      {
        name: user.name,
        profile_image_90: user.profile_image_90,
        username: user.username
      }.to_json
    end

    attribute :organization, if: proc { |a| a.organization.present? } do |article|
      organization = article.organization

      # Without the to_json we might not have properly escaped key/value pairs.  See above.
      {
        name: organization.name,
        profile_image_90: article.organization.profile_image_90,
        slug: organization.slug
      }.to_json
    end
  end
end
