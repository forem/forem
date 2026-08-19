class OrgCustomDomainConstraint
  PLATFORM_FIRST_SEGMENTS = %w[
    ahoy
    api
    assets
    async_info
    auth_pass
    badge_achievements
    bb
    billboard_events
    billboards
    display_ads
    feedback_messages
    feed_events
    followed_articles
    packs
    poll_votes
    rails
    reactions
    reading_list_items
  ].to_set.freeze

  RESERVED_SLUG_REGEXP = %r{(?!(?:api|assets|packs|rails|r|ahoy|enter|users|p|robots|sitemap-.+|async_info|reactions|billboards|bb|display_ads|auth_pass|search|poll_votes|badge_achievements|billboard_events|reading_list_items|followed_articles|feedback_messages|feed_events)\z)[^/.]+}

  def self.custom_domain_org(request)
    first_segment = request.path.to_s.split("/")[1]

    if PLATFORM_FIRST_SEGMENTS.include?(first_segment) && request.params[:i] != "i"
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
