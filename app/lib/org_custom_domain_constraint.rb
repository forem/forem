class OrgCustomDomainConstraint
  def self.custom_domain_org(request)
    is_ajax = request.respond_to?(:xhr?) && request.xhr?
    is_json = request.path.to_s.end_with?(".json") || (request.respond_to?(:accept) && request.accept.to_s.include?("application/json"))

    fetch_mode, fetch_dest =
      if request.respond_to?(:get_header)
        [request.get_header("HTTP_SEC_FETCH_MODE"), request.get_header("HTTP_SEC_FETCH_DEST")]
      elsif request.respond_to?(:headers)
        [request.headers["Sec-Fetch-Mode"], request.headers["Sec-Fetch-Dest"]]
      else
        [nil, nil]
      end

    is_fetch = fetch_mode == "cors" || fetch_dest == "empty"
    is_async_path = request.path.to_s.start_with?("/async_info", "/reactions")

    if (is_ajax || is_json || is_fetch || is_async_path) && request.params[:i] != "i"
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
