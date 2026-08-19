class OrgCustomDomainConstraint
  CUSTOM_DOMAIN_ROOT_SEGMENTS = %w[p feed rss].to_set.freeze

  def self.platform_first_segments
    @platform_first_segments ||= begin
      segments = Set.new
      Rails.application.routes.routes.each do |route|
        path_spec = route.path.spec.to_s
        # Remove optional leading scopes like (/locale/:locale) or (/:locale)
        cleaned_path = path_spec.gsub(/\(\/?(?:locale\/)?:?[a-z0-9_]+\)/, "")
        first_segment = cleaned_path.split("/").reject(&:blank?).first&.gsub(/[\(\.\:].*/, "")
        next if first_segment.blank? || first_segment.start_with?(":", "*")
        next if CUSTOM_DOMAIN_ROOT_SEGMENTS.include?(first_segment)

        controller = route.defaults[:controller].to_s
        action = route.defaults[:action].to_s

        # Exclude custom domain routes themselves so custom domain routes are not treated as platform paths
        next if controller == "stories" && action.in?(%w[custom_domain_index custom_domain_show])
        next if controller == "articles" && action == "feed"

        segments << first_segment
      end
      segments.freeze
    end
  end

  def self.custom_domain_org(request)
    first_segment = request.path.to_s.split("/")[1]

    if platform_first_segments.include?(first_segment) && request.params[:i] != "i"
      return nil
    end

    request.env["forem.custom_domain_org"] ||= custom_domain_org_for_host(request.host)
  end

  def self.custom_domain_org_for_host(host)
    normalized_host = host&.downcase
    return nil if normalized_host.blank? || normalized_host == Settings::General.app_domain&.downcase
    return nil if Subforem.cached_domains.include?(normalized_host)

    cache_key = "org_custom_domain_id:#{normalized_host}"
    org_id = MemoryFirstCache.fetch(cache_key) do
      org = Organization.find_by(custom_domain: normalized_host)
      org ? org.id : "not_found"
    end

    if org_id.present? && org_id != "not_found"
      org = Organization.find_by(id: org_id)
      if org && org.custom_domain == normalized_host && FeatureFlag.enabled?(:org_custom_domain, FeatureFlag::Actor.new(org))
        org
      else
        MemoryFirstCache.delete(cache_key) if org.nil? || org.custom_domain != normalized_host
        nil
      end
    else
      nil
    end
  end

  def matches?(request)
    OrgCustomDomainConstraint.custom_domain_org(request).present?
  end
end
