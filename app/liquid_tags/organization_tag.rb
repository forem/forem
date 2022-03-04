class OrganizationTag < LiquidTagBase
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  PARTIAL = "organizations/liquid".freeze

  def initialize(_tag_name, input, _parse_context)
    super

    org_slug = input.gsub("#{URL.url}/", "").delete(" ")
    @organization = parse_slug_to_organization(org_slug)
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

  def parse_slug_to_organization(org_slug)
    organization = Organization.find_by(slug: org_slug)
    raise StandardError, I18n.t("liquid_tags.organization_tag.invalid_slug") if organization.nil?

    organization
  end
end

Liquid::Template.register_tag("organization", OrganizationTag)
Liquid::Template.register_tag("org", OrganizationTag)
