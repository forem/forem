class OrganizationTag < LiquidTagBase
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  PARTIAL = "organizations/liquid".freeze

  # @todo What if someone provides https://dev.to/terms-of-service.  That will meet this criteria.
  #       How do we want to consider handling that situation?  My assumption is that we might want
  #       to test if the org_slug is a valid organization before we even let the OrganizationTag say
  #       there's a match.
  REGISTRY_REGEXP = %r{#{URL.url}/(?<org_slug>[\w-]+)/?}

  def initialize(_tag_name, organization, _parse_context)
    super
    @organization = parse_slug_to_organization(strip_tags(organization))
    @follow_button = follow_button(@organization)
    @organization_colors = user_colors(@organization)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        organization: @organization.decorate,
        follow_button: @follow_button,
        organization_colors: @organization_colors
      },
    )
  end

  def parse_slug_to_organization(organization)
    forem_domain = URL.url
    if organization.starts_with?(forem_domain)
      match = pattern_match_for(organization, [REGISTRY_REGEXP])
      raise StandardError, I18n.t("liquid_tags.organization_tag.invalid_url") unless match

      organization = Organization.find_by(slug: match[:org_slug])
    else
      organization = Organization.find_by(slug: organization)
    end

    raise StandardError, I18n.t("liquid_tags.organization_tag.invalid_slug") if organization.nil?

    organization
  end
end

Liquid::Template.register_tag("organization", OrganizationTag)
Liquid::Template.register_tag("org", OrganizationTag)

UnifiedEmbed.register(OrganizationTag, regexp: OrganizationTag::REGISTRY_REGEXP)
