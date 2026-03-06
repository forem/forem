class OrgTeamTag < LiquidTagBase
  PARTIAL = "liquids/org_team".freeze
  VALID_CONTEXTS = %w[Organization].freeze

  VALID_OPTIONS = %w[limit role].freeze
  VALID_ROLES = %w[all admins members].freeze
  MAX_LIMIT = 50
  DEFAULT_LIMIT = 50
  OPTION_REGEXP = /\A(\w+)=(\S+)\z/

  def initialize(_tag_name, input, _parse_context)
    super
    tokens = input.strip.split
    @org_slug = tokens.first
    @organization = Organization.find_by(slug: @org_slug)
    raise StandardError, I18n.t("liquid_tags.org_team_tag.invalid_slug") unless @organization

    parse_options(tokens.drop(1))
  end

  def render(_context)
    users = build_query
      .order(Arel.sql("users.badge_achievements_count DESC NULLS LAST, users.id ASC"))
      .limit(@limit)

    ApplicationController.render(
      partial: PARTIAL,
      locals: { users: users, organization: @organization, limit: @limit },
    )
  end

  private

  def parse_options(option_tokens)
    @limit = DEFAULT_LIMIT
    @role = "all"

    option_tokens.each do |token|
      match = token.match(OPTION_REGEXP)
      raise StandardError, I18n.t("liquid_tags.org_team_tag.invalid_option", option: token) unless match

      key, value = match[1], match[2]
      raise StandardError, I18n.t("liquid_tags.org_team_tag.invalid_option", option: key) unless VALID_OPTIONS.include?(key)

      send(:"parse_#{key}", value)
    end
  end

  def parse_limit(value)
    @limit = Integer(value, exception: false)
    unless @limit && @limit >= 1 && @limit <= MAX_LIMIT
      raise StandardError, I18n.t("liquid_tags.org_team_tag.invalid_limit")
    end
  end

  def parse_role(value)
    unless VALID_ROLES.include?(value)
      raise StandardError, I18n.t("liquid_tags.org_team_tag.invalid_role")
    end

    @role = value
  end

  def build_query
    case @role
    when "admins"
      @organization.users.joins(:organization_memberships)
        .where(organization_memberships: { organization_id: @organization.id, type_of_user: "admin" })
    when "members"
      @organization.users.joins(:organization_memberships)
        .where(organization_memberships: { organization_id: @organization.id, type_of_user: "member" })
    else
      @organization.active_users
    end
  end
end

Liquid::Template.register_tag("org_team", OrgTeamTag)
