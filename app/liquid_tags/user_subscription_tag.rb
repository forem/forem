class UserSubscriptionTag < LiquidTagBase
  PARTIAL = "liquids/user_subscription".freeze
  VALID_CONTEXTS = %w[Article].freeze
  VALID_ROLES = [
    :admin,
    [:restricted_liquid_tag, LiquidTags::UserSubscriptionTag],
    :super_admin,
  ].freeze

  # @see LiquidTagBase.user_authorization_method_name for discussion
  def self.user_authorization_method_name
    :user_subscription_tag_available?
  end

  def initialize(_tag_name, cta_text, parse_context)
    super
    @cta_text = cta_text.strip
    @source = parse_context.partial_options[:source]
    @user = parse_context.partial_options[:user]
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        cta_text: @cta_text,
        author_profile_image: @user&.profile_image_90,
        author_username: @user&.username,
        community_name: Settings::Community.community_name
      },
    )
  end
end

Liquid::Template.register_tag("user_subscription", UserSubscriptionTag)
