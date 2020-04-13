# <https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema>
class AuthorizationService
  def initialize(auth_payload, current_user: nil, cta_variant: nil)
    @auth_payload = auth_payload
    @provider = load_auth_provider(auth_payload.provider)

    @current_user = current_user
    @cta_variant = cta_variant
  end

  def get_user
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
  # TODO: raise exception if provider is available but not enabled for this app
  # TODO: available providers, enabled providers, unknownprovider exception
  def load_auth_provider(provider_name)
    "Authentication::Providers::#{provider_name.titleize}".constantize
  rescue NameError => e
    raise ::Authentication::Errors::ProviderNotFound, e
  end

  def prepare_identity
    Identity.from_omniauth(provider, auth_payload).tap do |identity|
      # update the identity in the DB if it belongs to a known user
      identity.save! if identity.user
    end
  end

  def user_identity_exists?
    current_user && Identity.exists?(provider: provider.name, user: current_user)
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

    existing_user = User.where(provider::USERNAME_FIELD => info.nickname).take
    return existing_user if existing_user

    User.new.tap do |user|
      user.assign_attributes(provider.new_user_data(auth_payload))
      user.assign_attributes(default_user_fields)

      user.skip_confirmation!
      user.set_remember_fields
      user.save!
    end
  end

  def default_user_fields
    {
      password: Devise.friendly_token(20),
      signup_cta_variant: cta_variant,
      saw_onboarding: false,
      editor_version: :v2
    }
  end

  def update_user(user)
    user.tap do |model|
      user.assign_attributes(provider.existing_user_data(auth_payload))

      model.set_remember_fields
      # TODO: do we really care about this? if the username has not changed, the value
      # will be the same as before, so we can just override this all the time
      model.github_username = auth_payload.info.nickname if provider.name == "github" && auth_payload.info.nickname != user.github_username
      model.twitter_username = auth_payload.info.nickname if provider.name == "twitter" && auth_payload.info.nickname != user.twitter_username
      model.profile_updated_at = Time.current if user.twitter_username_changed? || user.github_username_changed?
      model.save!
    end
  end

  def set_identity(identity, user)
    return if identity.user_id.present?

    identity.user = user
    identity.save!
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
