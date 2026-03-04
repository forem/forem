class OrgTeamTag < LiquidTagBase
  PARTIAL = "liquids/org_team".freeze
  VALID_CONTEXTS = %w[Organization].freeze

  def initialize(_tag_name, input, _parse_context)
    super
    @org_slug = input.strip
    @organization = Organization.find_by(slug: @org_slug)
    raise StandardError, I18n.t("liquid_tags.org_team_tag.invalid_slug") unless @organization
  end

  def render(_context)
    users = @organization.active_users
      .order(Arel.sql("users.badge_achievements_count DESC NULLS LAST, users.id ASC"))
      .limit(50)

    ApplicationController.render(
      partial: PARTIAL,
      locals: { users: users, organization: @organization },
    )
  end
end

Liquid::Template.register_tag("org_team", OrgTeamTag)
