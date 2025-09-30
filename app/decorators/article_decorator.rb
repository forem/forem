class ArticleDecorator < ApplicationDecorator
  LONG_MARKDOWN_THRESHOLD = 900

  # @return [String] JSON formatted string.
  #
  # @example
  #   > Article.last.decorate.user_data_info_to_json
  #   => "{\"user_id\":1,\"className\":\"User\",\"style\":\"full\",\"name\":\"Duane \\\"The Rock\\\" Johnson\"}"
  def user_data_info_to_json
    DataInfo.to_json(object: cached_user, class_name: "User", id: user_id, style: "full")
  end

  def current_state
    state = if !published?
              "unpublished"
            elsif scheduled?
              "scheduled"
            else
              "published"
            end
    ActiveSupport::StringInquirer.new(state)
  end

  def current_state_path
    current_state.published? ? "/#{username}/#{slug}" : "/#{username}/#{slug}?preview=#{password}"
  end

  def processed_canonical_url
    if canonical_url.present?
      canonical_url.to_s.strip
    else
      url
    end
  end

  def cached_tag_list_array
    (cached_tag_list || "").split(", ")
  end

  def url
    URL.url(path)
  end

  def title_length_classification
    if title.size > 105
      "longest"
    elsif title.size > 80
      "longer"
    elsif title.size > 60
      "long"
    elsif title.size > 22
      "medium"
    else
      "short"
    end
  end

  def published_at_int
    published_at.to_i
  end

  def title_with_query_preamble(user_signed_in)
    clean_title = title_for_metadata
    if search_optimized_title_preamble.present? && !user_signed_in
      "#{search_optimized_title_preamble}: #{clean_title}"
    else
      clean_title
    end
  end

  def description_and_tags
    return search_optimized_description_replacement if search_optimized_description_replacement.present?

    modified_description = description.strip
    modified_description += "." unless description.end_with?(".")
    return modified_description if cached_tag_list.blank?

    modified_description + I18n.t("decorators.article_decorator.tagged_with", cached_tag_list: cached_tag_list)
  end

  def video_metadata
    {
      id: id,
      video_code: video_code,
      video_source_url: video_source_url,
      video_thumbnail_url: cloudinary_video_url,
      video_closed_caption_track_url: video_closed_caption_track_url
    }
  end

  def has_recent_comment_activity?(timeframe = 1.week.ago)
    return false if last_comment_at.blank?

    last_comment_at > timeframe
  end

  def long_markdown?
    body_markdown.present? && body_markdown.size > LONG_MARKDOWN_THRESHOLD
  end

  def co_authors
    User.select(:name, :username).where(id: co_author_ids).order(created_at: :asc)
  end

  def co_author_name_and_path
    User.select(:name, :username).where(id: co_author_ids).in_order_of(:id, co_author_ids).map do |user|
      %(<a href="#{user.path}" class="crayons-link">#{user.name}</a>)
    end.to_sentence
  end

  # Used in determining when to bust additional routes for an Article's comments
  def discussion?
    cached_tag_list_array.include?("discuss") && published_at.to_i > 35.hours.ago.to_i
  end

  def permit_adjacent_sponsors?
    return true unless respond_to?(:user_id) && user_id.present?

    author_ids = [user_id] + co_author_ids
    Users::Setting.where(user_id: author_ids).all?(&:permit_adjacent_sponsors)
  end

  def pinned?
    return false unless persisted?

    id == PinnedArticle.id
  end

  delegate :readable_publish_date, to: :object

  delegate :video_duration_in_minutes, to: :object

  delegate :flare_tag, to: :object

  delegate :class_name, to: :object

  delegate :cloudinary_video_url, to: :object

  delegate :published_timestamp, to: :object

  delegate :main_image_background_hex_color, to: :object

  delegate :public_reaction_categories, to: :object

  delegate :body_preview, to: :object

  delegate :title_finalized, to: :object

  delegate :title_finalized_for_feed, to: :object
  delegate :skip_indexing?, to: :object
  delegate :displayable_published_at, to: :object
  delegate :title_for_metadata, to: :object
end
