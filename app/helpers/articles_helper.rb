module ArticlesHelper
  def hasVid(article)
    article.processed_html.include?("youtube.com/embed/") || article.processed_html.include?("player.vimeo.com") || article.comments_blob.include?("youtube")
  end

  def collection_link_class(current_article, linked_article)
    if current_article.id == linked_article.id
      "current-article"
    elsif !linked_article.published
      "coming-soon"
    end
  end

  def image_tag_or_inline_svg(service_name)
    if internal_navigation?
      image_tag("#{service_name}-logo.svg", class: "icon-img")
    else
      inline_svg("#{service_name}-logo.svg", class: "icon-img")
    end
  end

  def should_show_updated_on?(article)
    article.edited_at &&
      article.published &&
      !article.published_from_feed &&
      article.published_at.next_day < article.edited_at
  end

  def should_show_crossposted_on?(article)
    article.crossposted_at &&
      article.published_from_feed &&
      article.published &&
      article.published_at &&
      article.feed_source_url.present?
  end

  def get_host_without_www(url)
    url = "http://#{url}" if URI.parse(url).scheme.nil?
    host = URI.parse(url).host.downcase
    host.gsub!("medium.com", "Medium") if host.include?("medium.com")
    host.start_with?("www.") ? host[4..-1] : host
  end

  def hiring_form?(tag, article)
    tag.to_s == "hiring" || article.tag_list.include?("hiring")
  end
end
