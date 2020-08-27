module Profiles
  class Update
    def self.call(profile, updated_attributes = {})
      new(profile, updated_attributes).call
    end

    attr_reader

    def initialize(profile, updated_attributes)
      @profile = profile
      @updated_attributes = updated_attributes
      @success = false
    end

    def call
      # Ensure we have up to date attributes
      Profile.refresh_attributes!

      # We don't update `data` directly. This uses the defined store_attributes
      # so we can make use of their typecasting.
      @profile.assign_attributes(@updated_attributes)

      # Before saving, filter out obsolete profile fields
      @profile.data.slice!(*Profile.attributes)

      return unless @profile.save

      # Propagate changes back to the `users` table
      user_attributes = @profile.data.transform_keys do |key|
        Profile::MAPPED_ATTRIBUTES.fetch(key, key).to_s
      end
      @profile.user._skip_profile_sync = true
      @success = true if @profile.user.update(user_attributes)
      @profile.user._skip_profile_sync = false
      self
    end

    def success?
      @success
    end
  end
end
