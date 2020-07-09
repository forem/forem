module OrganizationHelper
  def orgs_with_credits(organizations)
    options = organizations.map do |org|
      ["#{org.name} (#{org.unspent_credits_count})", org.id]
    end
    options_for_select(options)
  end
end
