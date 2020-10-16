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

      # Handle user specific custom profile fields
      custom_attributes = @updated_attributes.extract!(*@profile.custom_profile_attributes)
      @updated_attributes[:custom_attributes] = custom_attributes

      # We don't update `data` directly. This uses the defined store_attributes
      # so we can make use of their typecasting.
      @profile.assign_attributes(@updated_attributes)

      # Before saving, filter out obsolete profile fields
      @profile.data.slice!(*Profile.attributes)

      return unless @profile.save

      # Propagate changes back to the `users` table
      self
    end

    def success?
      @success
    end
  end
end
