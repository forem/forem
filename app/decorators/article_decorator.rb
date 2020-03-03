class ArticleDecorator < ApplicationDecorator
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

  def internal_utm_params(place = "additional_box")
    org_slug = organization&.slug

    campaign = if boosted_additional_articles
                 "#{org_slug}_boosted"
               else
                 "regular"
               end

    "?utm_source=#{place}&utm_medium=internal&utm_campaign=#{campaign}&booster_org=#{org_slug}"
  end

  def published_at_int
    published_at.to_i
  end

  def description_and_tags
    modified_description = description.strip
    modified_description += "." unless description.end_with?(".")
    return modified_description if cached_tag_list.blank?

    modified_description + " Tagged with #{cached_tag_list}."
  end
end
