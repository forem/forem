class OrgCustomDomainConstraint
  def matches?(request)
    is_ajax = request.respond_to?(:xhr?) && request.xhr?
    is_json = request.path.to_s.end_with?(".json") || request.respond_to?(:accept) && request.accept.to_s.include?("application/json")

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
      return false
    end

    host = request.host&.downcase
    return false if host == Settings::General.app_domain || host.blank?
    return false if Subforem.cached_domains.include?(host)

    cache_key = "org_custom_domain_id:#{host}"
    org_id = Rails.cache.read(cache_key)
    org = Organization.find_by(id: org_id) if org_id && org_id != "not_found"

    if org && org.custom_domain != host
      Rails.cache.delete(cache_key)
      org = nil
    end

    unless org
      # Return false early for cached misses (1 min TTL)
      return false if org_id == "not_found"

      org = Organization.find_by(custom_domain: host)
      if org
        Rails.cache.write(cache_key, org.id, expires_in: 10.minutes)
      else
        Rails.cache.write(cache_key, "not_found", expires_in: 1.minute)
        return false
      end
    end

    if FeatureFlag.enabled?(:org_custom_domain, FeatureFlag::Actor.new(org))
      request.env["forem.custom_domain_org"] = org
      true
    else
      false
    end
  end
end
