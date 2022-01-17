module OrganizationHelper
  def orgs_with_credits(organizations)
    options = organizations.map do |org|
      [I18n.t("helpers.organization_helper.option", org_name: org.name, unspent: org.unspent_credits_count), org.id]
    end
    options_for_select(options)
  end
end
