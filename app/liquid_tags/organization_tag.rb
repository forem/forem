class OrganizationTag < LiquidTagBase
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  PARTIAL = "organizations/liquid".freeze

  def initialize(_tag_name, organization, _tokens)
    @organization = parse_slug_to_organization(organization.delete(" "))
    @follow_button = follow_button(@organization)
    @organization_colors = user_colors(@organization)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        organization: @organization,
        follow_button: @follow_button,
        organization_colors: @organization_colors
      },
    )
  end

  def parse_slug_to_organization(organization)
    organization = Organization.find_by(slug: organization)
    raise StandardError, "Invalid organization slug" if organization.nil?

    organization
  end
end

Liquid::Template.register_tag("organization", OrganizationTag)
Liquid::Template.register_tag("org", OrganizationTag)
