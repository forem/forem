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
    @organization = Organization.find_by_slug_or_legacy(@org_slug)
    raise StandardError, I18n.t("liquid_tags.org_team_tag.invalid_slug") unless @organization

    parse_options(tokens.drop(1))
  end

  def render(_context)
    users = @organization.active_users
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
    # Keep accepting existing markup without exposing membership roles in public output.
    unless VALID_ROLES.include?(value)
      raise StandardError, I18n.t("liquid_tags.org_team_tag.invalid_role")
    end
  end
end

Liquid::Template.register_tag("org_team", OrgTeamTag)
