class AuthorizationService
  def initialize(auth_payload, current_user = nil, cta_variant = nil)
    @auth_payload = auth_payload
    @provider = load_auth_provider(auth_payload.provider)

    @current_user = current_user
    @cta_variant = cta_variant
  end

  def get_user
    # NOTE: what is this for?
    auth_payload.extra.delete("access_token") if auth_payload.extra.access_token

    identity = prepare_identity

    return current_user if user_identity_exists?

    user = proper_user(identity)

    user = if user.nil?
             build_user
           else
             update_user(user)
           end

    set_identity(identity, user)
    user.skip_confirmation!
    flag_spam_user(user) if account_less_than_a_week_old?(user, identity)
    user
  end

  private

  attr_accessor :auth_payload, :current_user, :provider, :cta_variant

  # Loads the proper auth provider from the available ones
  # TODO: raise exception if provider doesn't exist at all
  # TODO: raise exception if provider is available but not enabled for this app
  # TODO: available providers, enabled providers, unknownprovider exception
  def load_auth_provider
    provider_name = auth_payload.provider.titleize
    "Authentication::Providers::#{provider_name}".safe_constantize
  end

  def prepare_identity
    Identity.from_omniauth(auth_payload).tap do |identity|
      # this will update the identity in the DB if it belongs to a known user
      identity.save! if identity.user
    end
  end

  def proper_user(identity)
    if current_user
      current_user
    elsif identity.user
      identity.user
    elsif auth_payload.info.email.present?
      User.find_by(email: auth_payload.info.email)
    end
  end

  def build_user
    info = auth_payload.info

    existing_user = User.where("#{provider}_username" => info.nickname).take
    return existing_user if existing_user

    User.new.tap do |user|
      user.name = auth_payload.extra.raw_info.name || info.nickname

      # TODO
      user.github_username = (info.nickname if provider == "github")
      user.twitter_username = (info.nickname if provider == "twitter")

      user.email = info.email || ""
      user.password = Devise.friendly_token(20)

      user.remote_profile_image_url = (info.image || "").gsub("_normal", "")

      user.signup_cta_variant = cta_variant
      user.saw_onboarding = false

      user.editor_version = "v2"

      user.skip_confirmation!
      user.set_remember_fields

      add_social_identity_data(user)

      user.save!
    end
  end

  def update_user(user)
    user.set_remember_fields
    # TODO: do we really care about this? if the username has not changed, the value
    # will be the same as before, so we can just override this all the time
    user.github_username = auth_payload.info.nickname if provider == "github" && auth_payload.info.nickname != user.github_username
    user.twitter_username = auth_payload.info.nickname if provider == "twitter" && auth_payload.info.nickname != user.twitter_username
    add_social_identity_data(user)
    user.profile_updated_at = Time.current if user.twitter_username_changed? || user.github_username_changed?
    user.save
    user
  end

  def add_social_identity_data(user)
    # NOTE: is there a case for this?
    return unless auth_payload&.provider && auth_payload&.extra && auth_payload.extra.raw_info

    if provider == "twitter"
      user.twitter_created_at = auth_payload.extra.raw_info.created_at
      user.twitter_followers_count = auth_payload.extra.raw_info.followers_count.to_i
      user.twitter_following_count = auth_payload.extra.raw_info.friends_count.to_i
    else
      user.github_created_at = auth_payload.extra.raw_info.created_at
    end
  end

  def set_identity(identity, user)
    return if identity.user_id.present?

    identity.user = user
    identity.save!
  end

  def user_identity_exists?
    current_user && Identity.exists?(provider: provider, user: current_user)
  end

  def account_less_than_a_week_old?(user, logged_in_identity)
    user_identity_age = user.github_created_at ||
      user.twitter_created_at ||
      Time.zone.parse(logged_in_identity.auth_data_dump.extra.raw_info.created_at)
    # last one is a fallback in case both are nil
    range = 1.week.ago.beginning_of_day..Time.current
    range.cover?(user_identity_age)
  end

  def flag_spam_user(user)
    Slack::Messengers::PotentialSpammer.call(user: user)
  end
end
