module FeatureFlagUrlHelper
  # this will need to be done for every admin helpe, but it will be localized
  # this file and can be removed once we've tested the new route structure

  def admin_tags_path(**kwargs)
    determine_path("content_manager", "tags", kwargs)
  end

  def admin_articles_path(**kwargs)
    determine_path("content_manager", "articles", kwargs)
  end
end

private

def determine_path(scope, resource, kwargs)
  if FeatureFlag.enabled?(:admin_restructure)
    str = "/admin/#{scope}/#{resource}"
    if kwargs
      str += "?#{kwargs.map { |k, v| "#{k}=#{v}" }.join('&')}"
    end
    str
  else
    super
  end
end
