module Homepage
  class ArticleSerializer < ApplicationSerializer
    attributes(
      :class_name,
      :cloudinary_video_url,
      :comments_count,
      # :flare_tag,
      :id,
      :path,
      :public_reactions_count,
      :readable_publish_date,
      :reading_time,
      :title,
      :user_id,
      :video_duration_string,
    )

    attribute :video_duration_string, &:video_duration_in_minutes
    attribute :published_at_int, ->(article) { article.published_at.to_i }
    attribute :tag_list, ->(article) { article.cached_tag_list.to_s.split(", ") }

    attribute :user do |article|
      user = article.user

      {
        name: user.name,
        profile_image_90: user.profile_image_90,
        username: user.username
      }
    end

    attribute :organization, if: proc { |a| a.organization.present? } do |article|
      organization = article.organization

      {
        name: organization.name,
        profile_image_90: article.organization.profile_image_90,
        slug: organization.slug
      }
    end
  end
end
