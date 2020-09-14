module Profiles
  class Update
    def self.call(profile, updated_attributes = {})
      new(profile, updated_attributes).call
    end

    attr_reader :error_message

    def initialize(user, updated_attributes)
      @user = user
      @profile = user.profile
      @updated_profile_attributes = updated_attributes[:profile]
      @updated_user_attributes = updated_attributes[:user]
      @success = false
    end

    def call
      update_profile
    end

    def success?
      @success
    end

    private

    def update_profile
      # Ensure we have up to date attributes
      Profile.refresh_attributes!

      # We don't update `data` directly. This uses the defined store_attributes
      # so we can make use of their typecasting.
      @profile.assign_attributes(@updated_profile_attributes)

      # Before saving, filter out obsolete profile fields
      @profile.data.slice!(*Profile.attributes)

      return unless @profile.save

      # Propagate changes back to the `users` table
      user_attributes = @profile.data.transform_keys do |key|
        Profile::MAPPED_ATTRIBUTES.fetch(key, key).to_s
      end
      @profile.user._skip_profile_sync = true
      if @profile.user.update(user_attributes)
        update_user
      else
        @error_message = @user.errors_as_sentence
      end
      @profile.user._skip_profile_sync = false
      self
    end

    def update_user
      if @user.update(@updated_user_attributes.to_h)
        @success = true
      else
        @error_message = @user.errors_as_sentence
      end
    end
  end
end
