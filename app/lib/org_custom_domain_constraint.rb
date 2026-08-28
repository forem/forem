class OrgCustomDomainConstraint
  PLATFORM_FIRST_SEGMENTS = %w[
    ahoy
    api
    assets
    async_info
    auth_pass
    badge_achievements
    bb
    bb_tabulations
    billboard_events
    billboards
    display_ad_events
    display_ads
    enter
    fallback_activity_recorder
    feedback_messages
    feed_events
    followed_articles
    packs
    poll_votes
    rails
    reactions
    reading_list_items
    search
    sign_out
    signout_confirm
    users
  ].to_set.freeze

  def self.platform_path?(first_segment, path)
    return true if PLATFORM_FIRST_SEGMENTS.include?(first_segment)
    return true if path.start_with?("/robots", "/sitemap", "/llms.")

    false
  end

  def self.custom_domain_org(request)
    path = request.path.to_s
    first_segment = path.split("/")[1]

    if platform_path?(first_segment, path) && request.params[:i] != "i"
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
