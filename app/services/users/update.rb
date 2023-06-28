module Users
  # Deals with updates that affect fields on +Profile+ and/or +User+ in a transparent way.
  class Update
    using HashAnyKey
    include ImageUploads

    CORE_PROFILE_FIELDS = %i[summary].freeze
    CORE_USER_FIELDS = %i[name username profile_image].freeze
    CORE_SETTINGS_FIELDS = %i[brand_color1].freeze

    # @param user [User] the user whose profile we are updating
    # @param updated_attributes [Hash<Symbol, Hash<Symbol, Object>>] the profile
    #   and/or user attributes to update. The corresponding has keys are +:user+ and
    #   +:profile+ respectively.
    # @example
    #   Users::Update.call(
    #     current_user,
    #     profile: { website_url: "https://example.com" },
    #   )
    # @return [Users::Update] a class instance that can be used for success checks
    def self.call(user, updated_attributes = {})
      new(user, updated_attributes).call
    end

    def initialize(user, updated_attributes)
      @user = user
      @profile = user.profile || user.create_profile
      @users_setting = user.setting
      @updated_profile_attributes = updated_attributes[:profile] || {}
      @updated_user_attributes = prepare_user_attributes(updated_attributes[:user], user)
      @updated_users_setting_attributes = updated_attributes[:users_setting].to_h || {}
      @errors = []
      @success = false
    end

    def call
      if update_successful?
        @success = true
        @user.touch(:profile_updated_at)
        conditionally_resave_articles
      else
        errors.concat(@profile.errors.full_messages)
        errors.concat(@user.errors.full_messages)
        errors.concat(@users_setting.errors.full_messages)
        Honeycomb.add_field("error", errors_as_sentence)
        Honeycomb.add_field("errored", true)
      end
      self
    end

    def success?
      @success
    end

    def errors_as_sentence
      errors.to_sentence
    end

    private

    attr_reader :errors

    def prepare_user_attributes(updated_user_attributes, user)
      attrs = updated_user_attributes.to_h || {}
      if attrs[:username] != user.username
        attrs[:old_username] = user.username
        attrs[:old_old_username] = user.old_username
      end
      attrs
    end

    def update_successful?
      return false unless verify_profile_image

      Profile.transaction do
        update_profile
        @user.update!(@updated_user_attributes)
        @users_setting.update!(@updated_users_setting_attributes)
      end
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    def verify_profile_image
      image = @updated_user_attributes[:profile_image]
      return true unless image
      return true if valid_image_file?(image) && valid_filename?(image)

      false
    end

    def valid_image_file?(image)
      return true if file?(image)

      errors.append(is_not_file_message)
      false
    end

    def valid_filename?(image)
      return true unless long_filename?(image)

      errors.append(filename_too_long_message)
      false
    end

    def update_profile
      # We don't update `data` directly. This uses the store_accessors instead.
      @profile.assign_attributes(@updated_profile_attributes)

      # Before saving, filter out obsolete profile fields
      @profile.data.slice!(*Profile.attributes)

      @profile.save!
    end

    def conditionally_resave_articles
      return unless resave_articles? && !@user.suspended?

      Users::ResaveArticlesWorker.perform_async(@user.id)
    end

    def resave_articles?
      user_fields = CORE_USER_FIELDS + Authentication::Providers.username_fields
      @updated_user_attributes.any_key?(user_fields) ||
        @updated_profile_attributes.any_key?(CORE_PROFILE_FIELDS) ||
        @updated_users_setting_attributes.any_key?(CORE_SETTINGS_FIELDS)
    end
  end
end
