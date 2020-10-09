module Profiles
  class Update
    def self.call(user, updated_attributes = {})
      new(user, updated_attributes).call
    end

    attr_reader :error_message

    def initialize(user, updated_attributes)
      @user = user
      @profile = user.profile
      @updated_profile_attributes = updated_attributes[:profile] || {}
      @updated_user_attributes = updated_attributes[:user] || {}
      @success = false
    end

    def call
      unless update_profile && sync_to_user
        Honeycomb.add_field("error", @error_message)
        Honeycomb.add_field("errored", true)
      end
      self
    end

    def success?
      @success
    end

    private

    def update_profile
      # Ensure we have up to date attributes
      Profile.refresh_attributes!

      # Handle user specific custom profile fields
      if (custom_profile_attributes = @profile.custom_profile_attributes).any?
        custom_attributes = @updated_profile_attributes.extract!(*custom_profile_attributes)
        @updated_profile_attributes[:custom_attributes] = custom_attributes
      end

      # We don't update `data` directly. This uses the defined store_attributes
      # so we can make use of their typecasting.
      @profile.assign_attributes(@updated_profile_attributes)

      # Before saving, filter out obsolete profile fields
      @profile.data.slice!(*Profile.attributes)

      @profile.save
    end

    # Propagate changes back to the `users` table
    def sync_to_user
      # These are the profile attributes that still exist as columns on User.
      profile_attributes = @profile.data.transform_keys do |key|
        Profile::MAPPED_ATTRIBUTES.fetch(key, key).to_s
      end
      @profile.user._skip_profile_sync = true
      if @profile.user.update(profile_attributes.except("custom_attributes"))
        update_user_attributes
      else
        @error_message = @user.errors_as_sentence
      end

      @user.touch(:profile_updated_at)
      @success
    ensure
      @profile.user._skip_profile_sync = false
    end

    def update_user_attributes
      if @user.update(@updated_user_attributes.to_h)
        @success = true
      else
        @error_message = @user.errors_as_sentence
      end
    end
  end
end
