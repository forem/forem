class OrgCustomDomainConstraint
  def matches?(request)
    host = request.host&.downcase
    return false if host == Settings::General.app_domain || host.blank?

    org = Organization.find_by(custom_domain: host)
    return false unless org

    if FeatureFlag.enabled?(:org_custom_domain, org)
      request.env["forem.custom_domain_org"] = org
      true
    else
      false
    end
  end
end
