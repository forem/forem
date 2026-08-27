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

      if (linked_identity = current_user_identity)
        refresh_identity(identity, linked_identity)
        return current_user
      end

      # These variables need to be set outside of the scope of the
      # transaction in order to be used after the transaction is completed.
      log_to_datadog = false
      new_mlh_identity = false
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

        # A newly linked mlh identity puts the MLH Core user id (its uid) into
        # User#trackable_payload, so surface a user_updated to the DEV → Core
        # sync — which keys off profile_updated_at.
        new_mlh_identity = new_identity && identity.provider == "mlh"
        user.profile_updated_at = Time.current if new_mlh_identity

        user.save!
        authed_user = user
      end

      Users::PrefillMlhProfileWorker.perform_async(authed_user.id) if new_mlh_identity

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

    def current_user_identity
      current_user&.identities&.find_by(provider: provider.name)
    end

    # A completed re-auth always refreshes the linked row's token and stored
    # auth payload with the just-received data. This matters most for an
    # identity created through the admin API rather than a completed OAuth
    # flow, which starts with no token and no payload at all.
    #
    # `incoming_identity` is built by `Identity.build_from_omniauth`, so it is
    # only persisted when the payload's provider + uid already exist in the
    # database. That gives three cases:
    #
    #   1. the payload is the row the user is already linked through: refresh
    #      it in place.
    #   2. the payload's uid is unclaimed and the linked row has no stored auth
    #      payload: that link was machine-created, and completing OAuth as the
    #      new uid proves the user owns it, so move the link onto it.
    #   3. anything else: no-op. A uid held by some other identity is never
    #      taken over, and a link the user established themselves is never
    #      silently moved.
    def refresh_identity(incoming_identity, linked_identity)
      if incoming_identity.persisted?
        return unless incoming_identity.id == linked_identity.id

        incoming_identity.save!
      elsif linked_identity.auth_data_dump.nil?
        repoint_identity(incoming_identity, linked_identity)
      end
    end

    # Moves a payload-less link onto the uid the user just authenticated as.
    # Touching the user afterwards is what surfaces the new uid to the outbound
    # sync, the same profile_updated_at signal a freshly linked identity sends.
    def repoint_identity(incoming_identity, linked_identity)
      ActiveRecord::Base.transaction do
        linked_identity.update!(
          uid: incoming_identity.uid,
          token: incoming_identity.token,
          secret: incoming_identity.secret,
          auth_data_dump: incoming_identity.auth_data_dump,
        )

        current_user.profile_updated_at = Time.current
        current_user.save!
      end
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
      # A concurrent request can claim the same provider + uid first. Leave the
      # existing link as it was rather than failing the whole callback.
      ForemStatsClient.increment(
        "identity.errors",
        tags: ["error:#{e.class}", "provider:#{linked_identity.provider}"],
      )
      nil
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
      # Safely extract raw_info, handling cases where auth_data_dump, extra, or raw_info may be nil
      # This can happen with some OAuth providers like MLH that may not provide raw_info
      auth_data = logged_in_identity.auth_data_dump
      return Time.current if auth_data.nil? || auth_data.extra.nil?

      raw_info = auth_data.extra.raw_info
      return Time.current if raw_info.nil?

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
