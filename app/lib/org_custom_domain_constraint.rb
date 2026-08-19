class OrgCustomDomainConstraint
  PLATFORM_PATH_PREFIXES = %w[
    /async_info
    /reactions
    /badge_achievements
    /billboard_events
    /billboards
    /bb
    /display_ads
    /poll_votes
    /reading_list_items
    /followed_articles
    /feedback_messages
    /feed_events
    /auth_pass
    /api
    /ahoy
    /assets
    /packs
    /rails
  ].freeze

  def self.custom_domain_org(request)
    path = request.path.to_s

    if PLATFORM_PATH_PREFIXES.any? { |prefix| path.start_with?(prefix) } && request.params[:i] != "i"
      return nil
    end

    host = request.host&.downcase
    return nil if host.blank? || host == Settings::General.app_domain
    return nil if Subforem.cached_domains.include?(host)

    request.env["forem.custom_domain_org"] ||= begin
      cache_key = "org_custom_domain_id:#{host}"
      org_id = MemoryFirstCache.fetch(cache_key) do
        org = Organization.find_by(custom_domain: host)
        org ? org.id : "not_found"
      end

      if org_id.present? && org_id != "not_found"
        org = Organization.find_by(id: org_id)
        if org && org.custom_domain == host && FeatureFlag.enabled?(:org_custom_domain, FeatureFlag::Actor.new(org))
          org
        else
          MemoryFirstCache.delete(cache_key) if org.nil? || org.custom_domain != host
          nil
        end
      else
        nil
      end
    end
  end

  def matches?(request)
    OrgCustomDomainConstraint.custom_domain_org(request).present?
  end
end
