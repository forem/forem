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
    return if article.processed_html.blank?

    article.processed_html.include?("youtube.com/embed/") ||
      article.processed_html.include?("player.vimeo.com") ||
      article.processed_html.include?("clips.twitch.tv/embed") ||
      article.comments_blob.include?("youtube")
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
    article.edited_at &&
      article.published &&
      !article.published_from_feed &&
      article.published_at.next_day < article.edited_at
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
    url = url.strip
    url = "http://#{url}" if Addressable::URI.parse(url).scheme.nil?
    host = Addressable::URI.parse(url).host.downcase
    host.gsub!("medium.com", "Medium")
    host.delete_prefix("www.")
  end

  def utc_iso_timestamp(timestamp)
    timestamp&.utc&.iso8601
  end

  def active_threads(...)
    Articles::ActiveThreadsQuery.call(...)
  end
end
