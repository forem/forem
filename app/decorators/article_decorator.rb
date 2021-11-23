class ArticleDecorator < ApplicationDecorator
  LONG_MARKDOWN_THRESHOLD = 900

  # This method answers whethor or not this decorated article can be
  # featured in the feed.
  #
  # @note From #15292 we want to no longer require the featured
  #       article to have an image.  However, there are some
  #       assumptions made in the view about featured articles having
  #       images.  Furthermore, by enabling a feature flag, if the
  #       code breaks we can toggle the requirement back on.
  #
  # @return [TrueClass] if this article can be "featured" in the feed
  # @return [FalseClass] if this article should not be "featured" in
  #         the feed
  #
  # @see ./app/views/stories/feeds/show.json.jbuilder for an example
  #      of usage
  def can_be_featured_in_feed
    return false unless featured
    return true if main_image.present?
    return true unless FeatureFlag.accessible?(:featured_story_must_have_main_image)

    false
  end

  # Why the alias?  Because an associated JSON builder uses the
  # can_be_featured_in_feed, but having the can_be_featured_in_feed?
  # method helps create conditions of least surprise.
  alias can_be_featured_in_feed? can_be_featured_in_feed

  def current_state_path
    published ? "/#{username}/#{slug}" : "/#{username}/#{slug}?preview=#{password}"
  end

  def processed_canonical_url
    if canonical_url.present?
      canonical_url.to_s.strip
    else
      url
    end
  end

  def comments_to_show_count
    cached_tag_list_array.include?("discuss") ? 75 : 25
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
    if search_optimized_title_preamble.present? && !user_signed_in
      "#{search_optimized_title_preamble}: #{title}"
    else
      title
    end
  end

  def description_and_tags
    return search_optimized_description_replacement if search_optimized_description_replacement.present?

    modified_description = description.strip
    modified_description += "." unless description.end_with?(".")
    return modified_description if cached_tag_list.blank?

    modified_description + " Tagged with #{cached_tag_list}."
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
    co_authors.map do |user|
      %(<a href="#{user.path}" class="crayons-link">#{user.name}</a>)
    end.to_sentence
  end

  # Used in determining when to bust additional routes for an Article's comments
  def discussion?
    cached_tag_list_array.include?("discuss") &&
      featured_number.to_i > 35.hours.ago.to_i
  end

  def pinned?
    return false unless persisted?

    id == PinnedArticle.id
  end
end
