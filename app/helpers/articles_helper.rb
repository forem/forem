module ArticlesHelper
  def should_show_latest_spam_suppression?(stories)
    return false if user_signed_in?
    return false unless stories.size > 1

    params[:timeframe] == Timeframe::LATEST_TIMEFRAME
  end

  def sort_options
    [
      [I18n.t("helpers.articles_helper.recently_created"), "creation-desc"],
      [I18n.t("helpers.articles_helper.recently_published"), "published-desc"],
      [I18n.t("helpers.articles_helper.most_views"), "views-desc"],
      [I18n.t("helpers.articles_helper.most_reactions"), "reactions-desc"],
      [I18n.t("helpers.articles_helper.most_comments"), "comments-desc"],
    ]
  end

  def has_vid?(article)
    return false if article.processed_html.blank?

    article.processed_html.include?("youtube.com/embed/") ||
      article.processed_html.include?("player.vimeo.com") ||
      article.processed_html.include?("clips.twitch.tv/embed") ||
      comments_include_youtube?(article)
  end

  def image_tag_or_inline_svg_tag(service_name, width: nil, height: nil)
    name = "#{service_name}.svg"

    if internal_navigation?
      image_tag(name, class: "icon-img", alt: "#{service_name} logo", width: width, height: height)
    else
      inline_svg_tag(
        name,
        class: "icon-img",
        aria: true,
        title: I18n.t("helpers.articles_helper.logo", service_name: service_name),
        width: width,
        height: height,
      )
    end
  end

  def should_show_updated_on?(article)
    article.edited_at.present? &&
      article.published &&
      !article.published_from_feed &&
      article.published_at.present? &&
      article.edited_at > article.published_at
  end

  def should_show_crossposted_on?(article)
    article.canonical_url ||
      (article.crossposted_at &&
      article.published_from_feed &&
      article.published &&
      article.published_at &&
      article.feed_source_url.present?)
  end

  def get_host_without_www(url)
    host = ForemNative.host_without_www(url) || legacy_host_without_www(url)
    host == "medium.com" ? "Medium" : host
  end

  # Handles the URLs ForemNative declines (non-ASCII text, userinfo, IP literals, ...).
  def legacy_host_without_www(url)
    url = url.strip
    url = "http://#{url}" if Addressable::URI.parse(url).scheme.nil?
    Addressable::URI.parse(url).host.downcase.delete_prefix("www.")
  end
  private :legacy_host_without_www

  def utc_iso_timestamp(timestamp)
    timestamp&.utc&.iso8601
  end

  def active_threads(...)
    Articles::ActiveThreadsQuery.call(...)
  end

  def comment_cue_message(count)
    count = count.to_i
    bucket = if count.zero?
               :zero
             elsif count <= 10
               :few
             else
               :many
             end
    t("views.articles.comment_cue.#{bucket}")
  end

  # Sanitizing an article body for RSS (a Nokogiri parse in plain_html plus a Loofah
  # scrub of every node) costs several ms per item, and the result depends only on
  # processed_html, so it is cached per distinct body and fetched in one round-trip.
  def feed_item_descriptions(articles, **sanitize_options)
    keys_by_article_id = articles.to_h do |article|
      [article.id, "rss_feed_description/v1/#{Digest::MD5.hexdigest(article.processed_html.to_s)}"]
    end
    articles_by_key = articles.index_by { |article| keys_by_article_id[article.id] }

    descriptions = Rails.cache.fetch_multi(*articles_by_key.keys, expires_in: 6.hours) do |key|
      sanitize(articles_by_key[key].plain_html, **sanitize_options).to_str
    end

    keys_by_article_id.transform_values { |key| descriptions[key] }
  end

  private

  def comments_include_youtube?(article)
    # Comment trees already loaded for this render hold every comment the page shows, so check them in memory
    loaded_trees = article.loaded_comment_trees
    return loaded_trees.any? { |tree| comment_tree_includes_youtube?(tree) } if loaded_trees.any?
    return false if article.displayed_comments_count.to_i.zero? && article.comments_count.to_i.zero?

    article.comments_blob.include?("youtube")
  end

  def comment_tree_includes_youtube?(tree)
    tree.any? do |comment, sub_comments|
      comment.body_markdown.to_s.include?("youtube") ||
        (sub_comments.present? && comment_tree_includes_youtube?(sub_comments))
    end
  end
end
