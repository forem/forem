module FeatureFlagUrlHelper
  # this will need to be done for every admin helper, but it will be localized to
  # this file and can be removed once we've tested the new route structure

  def admin_tags_path(**kwargs)
    return determine_path("content_manager", "tags", kwargs) if FeatureFlag.enabled?(:admin_restructure)

    super
  end

  def admin_articles_path(**kwargs)
    return determine_path("content_manager", "articles", kwargs) if FeatureFlag.enabled?(:admin_restructure)

    super
  end
end

private

def determine_path(scope, resource, kwargs)
  str = "/admin/#{scope}/#{resource}"
  if kwargs
    str += "?#{kwargs.map { |k, v| "#{k}=#{v}" }.join('&')}"
  end

  str
end
