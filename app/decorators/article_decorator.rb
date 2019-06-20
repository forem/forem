class ArticleDecorator < ApplicationDecorator
  delegate_all

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
    "https://#{ApplicationConfig['APP_DOMAIN']}#{path}"
  end

  def title_length_classification
    if article.title.size > 105
      "longest"
    elsif article.title.size > 80
      "longer"
    elsif article.title.size > 60
      "long"
    elsif article.title.size > 22
      "medium"
    else
      "short"
    end
  end

  def internal_utm_params(place = "additional_box")
    campaign = if boosted_additional_articles
                 "#{organization&.slug}_boosted"
               else
                 "regular"
               end
    "?utm_source=#{place}&utm_medium=internal&utm_campaign=#{campaign}&booster_org=#{organization&.slug}"
  end

  def published_at_int
    published_at.to_i
  end
end
