# Responsible for generating the asynchronus data of a user.  This is data that we send on the wire
# to the application for much of its user specific client-side rendering.
#
# @see AsyncInfoController#user_data
# @see UserDecorator
# @see ApplicationPolicy
class AsyncInfo
  # @api public
  #
  # Generate a Hash of the relevant user data.
  #
  # @param user [User, UserDecorator]
  # @param context [ApplicationController]
  # @return [Hash<Symbol,Object>]
  #
  # @see ApplicationController#feed_style_preference
  #
  # @todo The given feed_style_prefernce could be extracted to the user decorator.  We would need to
  #       account for a nil current user in our view logic.
  def self.to_hash(user:, context:)
    new(user: user, context: context).to_h
  end

  def initialize(user:, context:)
    @user = user.decorate
    @context = context
  end

  attr_reader :user, :context

  def to_h
    {
      id: user.id,
      name: user.name,
      username: user.username,
      profile_image_90: user.profile_image_url_for(length: 90),
      followed_tags: user.cached_followed_tags.to_json,
      followed_podcast_ids: user.cached_following_podcasts_ids,
      reading_list_ids: user.cached_reading_list_article_ids,
      blocked_user_ids: UserBlock.cached_blocked_ids_for_blocker(user.id),
      saw_onboarding: user.saw_onboarding,
      checked_code_of_conduct: user.checked_code_of_conduct,
      checked_terms_and_conditions: user.checked_terms_and_conditions,
      display_sponsors: user.display_sponsors,
      display_announcements: user.display_announcements,
      trusted: user.trusted?,
      moderator_for_tags: user.moderator_for_tags,
      config_body_class: user.config_body_class,
      feed_style: feed_style_preference,
      created_at: user.created_at,
      admin: user.any_admin?,
      policies: [
        {
          dom_class: ApplicationPolicy.base_dom_class_for(record: Article, query: :create?),
          visible: visible?(record: Article, query: :create?)
        },
        {
          dom_class: ApplicationPolicy.base_dom_class_for(record: Article, query: :moderate?),
          visible: visible?(record: Article, query: :moderate?)
        },
      ],
      apple_auth: user.email.to_s.end_with?("@privaterelay.appleid.com")
    }
  end

  private

  delegate :feed_style_preference, to: :context

  # @return [TrueClass] if policy allows the given query on the given record
  # @return [FalseClass] if policy raises Pundit::NotAuthorizedError
  # @return [FalseClass] if policy does not allow the given query on the given record
  def visible?(record:, query:)
    context.__send__(:policy, record).public_send(query)
  rescue Pundit::NotAuthorizedError
    false
  end
end
