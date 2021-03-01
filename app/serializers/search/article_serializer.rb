module Search
  class ArticleSerializer < ApplicationSerializer
    attribute :id, &:search_id

    attributes :approved, :body_text, :class_name, :cloudinary_video_url,
               :comments_count, :experience_level_rating, :experience_level_rating_distribution,
               :featured, :featured_number, :hotness_score,
               :main_image, :path, :public_reactions_count, :published,
               :published_at, :reactions_count, :reading_time, :score, :title

    # video_duration_in_minutes in Elasticsearch is mapped as an integer
    # however, it really is a string in the format 00:00 which is why we
    # added an extra field to handle that string
    attribute :video_duration_string, &:video_duration_in_minutes
    attribute :video_duration_in_minutes do |article|
      article.video_duration_in_seconds.to_i / 60
    end

    attribute :readable_publish_date_string, &:readable_publish_date

    attribute :flare_tag_hash, if: proc { |a| a.flare_tag.present? }, &:flare_tag

    attribute :tags do |article|
      article.tags.map do |tag|
        { name: tag.name, keywords_for_search: tag.keywords_for_search }
      end
    end

    attribute :user do |article|
      NestedUserSerializer.new(article.user).serializable_hash.dig(
        :data, :attributes
      )
    end

    attribute :organization, if: proc { |a| a.organization.present? } do |article|
      {
        slug: article.organization.slug,
        name: article.organization.name,
        id: article.organization.id,
        profile_image_90: article.organization.profile_image_90
      }
    end
  end
end
