module OrganizationHelper
  def orgs_with_credits(organizations)
    options = organizations.map do |org|
      [I18n.t("helpers.organization_helper.option", org_name: org.name, unspent: org.unspent_credits_count), org.id]
    end
    options_for_select(options)
  end

  # The DNS record name an organization enters at its DNS provider for its custom
  # domain, relative to its registrable domain: "blog" for blog.example.com and
  # "@" for the apex example.com.
  def custom_domain_dns_record_name(domain)
    PublicSuffix.parse(domain.to_s, default_rule: nil).trd.presence || "@"
  rescue PublicSuffix::Error
    domain.to_s
  end

  def custom_domain_apex?(domain)
    custom_domain_dns_record_name(domain) == "@"
  end
end
