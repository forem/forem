class OrgCustomDomainConstraint
  def matches?(request)
    host = request.host&.downcase
    return false if host == Settings::General.app_domain || host.blank?

    org_id = Rails.cache.fetch("org_custom_domain_id:#{host}", expires_in: 10.minutes) do
      Organization.where(custom_domain: host).pick(:id) || "not_found"
    end
    return false if org_id == "not_found"

    org = Organization.find_by(id: org_id)
    return false unless org

    if FeatureFlag.enabled?(:org_custom_domain, org)
      request.env["forem.custom_domain_org"] = org
      true
    else
      false
    end
  end
end
