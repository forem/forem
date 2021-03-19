module ArticlesHelper
  DASHBOARD_POSTS_SORT_OPTIONS = [
    ["Recently Created", "creation-desc"],
    ["Recently Published", "published-desc"],
    ["Most Views", "views-desc"],
    ["Most Reactions", "reactions-desc"],
    ["Most Comments", "comments-desc"],
  ].freeze

  def sort_options
    DASHBOARD_POSTS_SORT_OPTIONS
  end

  def has_vid?(article)
    return if article.processed_html.blank?

    article.processed_html.include?("youtube.com/embed/") ||
      article.processed_html.include?("player.vimeo.com") ||
      article.processed_html.include?("clips.twitch.tv/embed") ||
      article.comments_blob.include?("youtube")
  end

  def image_tag_or_inline_svg_tag(service_name, width: nil, height: nil)
    name = "#{service_name}-logo.svg"

    if internal_navigation?
      image_tag(name, class: "icon-img", alt: "#{service_name} logo", width: width, height: height)
    else
      inline_svg_tag(name, class: "icon-img", aria: true, title: "#{service_name} logo", width: width, height: height)
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
    url = "http://#{url}" if URI.parse(url).scheme.nil?
    host = URI.parse(url).host.downcase
    host.gsub!("medium.com", "Medium")
    host.delete_prefix("www.")
  end

  def utc_iso_timestamp(timestamp)
    timestamp&.utc&.iso8601
  end

  def active_threads(**options)
    Articles::ActiveThreadsQuery.call(options)
  end
end
