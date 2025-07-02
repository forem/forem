module Authentication
  # TODO: [@forem/oss] use strategy pattern for the three cases
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
    # @api public
    #
    # @see #initialize method for parameters
    #
    # @return [User] when the given provider is valid
    #
    # @raise [Authentication::Errors::PreviouslySuspended] when the user was already suspended
    # @raise [Authentication::Errors::SpammyEmailDomain] when the associated email is spammy
    def self.call(...)
      new(...).call
    end

    # auth_payload is the payload schema, see https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema
    def initialize(auth_payload, current_user: nil, cta_variant: nil)
      @provider = load_authentication_provider(auth_payload)

      @current_user = current_user
      @cta_variant = cta_variant
    end

    # @api private
    def call
      identity = Identity.build_from_omniauth(provider)
      guard_against_spam_from!(identity: identity)
      return current_user if current_user_identity_exists?

      # These variables need to be set outside of the scope of the
      # transaction in order to be used after the transaction is completed.
      log_to_datadog = false
      id_provider, authed_user = nil

      ActiveRecord::Base.transaction do
        user = proper_user(identity)

        user = if user.nil?
                 find_or_create_user!
               else
                 update_user(user)
               end
        user.set_initial_roles!

        identity.user = user if identity.user_id.blank?
        new_identity = identity.new_record?
        successful_save = identity.save!

        log_to_datadog = new_identity && successful_save
        id_provider = identity.provider

        flag_spam_user(user) if account_less_than_a_week_old?(user, identity)

        user.save!
        authed_user = user
      end

      if log_to_datadog
        # Notify DataDog if a new identity was successfully created.
        ForemStatsClient.increment("identity.created", tags: ["provider:#{id_provider}"])
      end

      # Return the successfully-authed used from the transaction.
      authed_user
    rescue StandardError => e
      # Notify DataDog if something goes wrong in the transaction,
      # and then ensure that we re-raise and bubble up the error.
      ForemStatsClient.increment("identity.errors", tags: ["error:#{e.class}", "message:#{e.message}"])
      raise e
    end

    private

    def guard_against_spam_from!(identity:)
      domain = identity.email.split("@")[-1]
      return unless domain
      return if Settings::Authentication.acceptable_domain?(domain: domain)

      message = I18n.t("services.authentication.authenticator.not_allowed")

      raise Authentication::Errors::SpammyEmailDomain, message
    end

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
        Rails.logger.debug { "Current user exists: #{current_user.id}" }
        current_user
      elsif identity.user
        Rails.logger.debug { "Identity user found: #{identity.user.id}" }
        identity.user
      elsif provider.user_email.present?
        user = User.find_by(email: provider.user_email)
        Rails.logger.debug { "User found by email: #{user&.id}" }
        user
      end
    end

    def find_or_create_user!
      username = provider.user_nickname
      suspended_user = Users::SuspendedUsername.previously_suspended?(username)
      raise ::Authentication::Errors::PreviouslySuspended if suspended_user

      existing_user = User.find_by(
        provider.user_username_field => username,
      )
      return existing_user if existing_user

      User.new.tap do |user|
        user.assign_attributes(provider.new_user_data)
        user.assign_attributes(default_user_fields)
        user.onboarding_subforem_id = RequestStore.store[:subforem_id] if RequestStore.store[:subforem_id].present?

        user.set_remember_fields
        user.skip_confirmation!

        # The user must be saved in the database before
        # we assign the user to a new identity.
        user.new_record? ? user.save! : user.save # Throw excption if new record.
      end
    end

    def default_user_fields
      password = Devise.friendly_token(20)
      {
        password: password,
        password_confirmation: password,
        signup_cta_variant: cta_variant,
        registered: true,
        registered_at: Time.current
      }
    end

    def update_user(user)
      return user if user.spam_or_suspended?

      user.tap do |model|
        model.unlock_access! if model.access_locked?

        if model.confirmed?
          # We don't want to update users' email or any other fields if they're
          # connecting an existing account that already has a confirmed email.
          model.assign_attributes(provider.existing_user_data.except(:email))
        else
          # If the user doesn't have a confirmed email we can update their email
          # and trust it because the auth provider confirmed email ownership
          model.assign_attributes(provider.existing_user_data)
        end

        update_profile_updated_at(model)

        model.set_remember_fields
      end
    end

    def update_profile_updated_at(user)
      field_name = "#{provider.user_username_field}_changed?"
      user.profile_updated_at = Time.current if user.public_send(field_name)
    end

    def account_less_than_a_week_old?(_user, logged_in_identity)
      user_identity_age = extract_created_at_from_payload(logged_in_identity)

      # last one is a fallback in case both are nil
      range = 1.week.ago.beginning_of_day..Time.current
      range.cover?(user_identity_age)
    end

    def extract_created_at_from_payload(logged_in_identity)
      raw_info = logged_in_identity.auth_data_dump.extra.raw_info

      if raw_info.created_at.present?
        Time.zone.parse(raw_info.created_at)
      elsif raw_info.auth_time.present?
        Time.zone.at(raw_info.auth_time)
      else
        Time.current
      end
    end

    def flag_spam_user(user)
      Slack::Messengers::PotentialSpammer.call(user: user)
    end
  end
end
