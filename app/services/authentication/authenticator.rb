module Authentication
  # TODO: [thepracticaldev/oss] use strategy pattern for the three cases
  #   described below.
  #   Make the decision early which one of the 3 cases we're dealing with
  #   and then call either NewUserStrategy, UpdateUserStrategy or
  #   LoggedInUserStrategy. I think the resulting three classes would be much
  #   easier to understand and they can still share methods by inheriting
  #   from a basic AuthStrategy.

  # Authenticator will perform one of these tree operations:
  # 1. create a new user and match it to its authentication identity
  # 2. update an existing user and align it to its authentication identity
  # 3. return the current user if a user is given (already logged in scenario)
  class Authenticator
    # auth_payload is the payload schema, see https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema
    def initialize(auth_payload, current_user: nil, cta_variant: nil)
      @provider = load_authentication_provider(auth_payload)

      @current_user = current_user
      @cta_variant = cta_variant
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      identity = Identity.build_from_omniauth(provider)

      return current_user if current_user_identity_exists?

      user = proper_user(identity)
      user = if user.nil?
               build_user
             else
               update_user(user)
             end

      save_identity(identity, user)

      user.skip_confirmation!

      flag_spam_user(user) if account_less_than_a_week_old?(user, identity)

      user.save!
      user
    end

    private

    attr_reader :provider, :current_user, :cta_variant

    # Loads the proper authentication provider from the available ones
    def load_authentication_provider(auth_payload)
      provider_class = Authentication::Providers.get!(auth_payload.provider)
      provider_class.new(auth_payload)
    end

    def current_user_identity_exists?
      current_user&.identities&.exists?(provider: provider.name)
    end

    def proper_user(identity)
      if current_user
        current_user
      elsif identity.user
        identity.user
      elsif provider.user_email.present?
        User.find_by(email: provider.user_email)
      end
    end

    def build_user
      existing_user = User.where(
        provider.user_username_field => provider.user_nickname,
      ).take
      return existing_user if existing_user

      User.new.tap do |user|
        user.assign_attributes(provider.new_user_data)
        user.assign_attributes(default_user_fields)

        user.set_remember_fields

        # save_identity() requires users to have been saved in the DB prior
        # to its execution, thus we need to make sure the new user is saved
        # before that
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
        user.assign_attributes(provider.existing_user_data)

        update_profile_updated_at(model)

        model.set_remember_fields
      end
    end

    def update_profile_updated_at(user)
      field_name = "#{provider.user_username_field}_changed?"
      user.profile_updated_at = Time.current if user.public_send(field_name)
    end

    def save_identity(identity, user)
      identity.user = user if identity.user_id.blank?
      identity.save!
    end

    def account_less_than_a_week_old?(user, logged_in_identity)
      provider_created_at = user.public_send(provider.user_created_at_field)
      user_identity_age = provider_created_at ||
        Time.zone.parse(logged_in_identity.auth_data_dump.extra.raw_info.created_at)

      # last one is a fallback in case both are nil
      range = 1.week.ago.beginning_of_day..Time.current
      range.cover?(user_identity_age)
    end

    def flag_spam_user(user)
      Slack::Messengers::PotentialSpammer.call(user: user)
    end
  end
end
