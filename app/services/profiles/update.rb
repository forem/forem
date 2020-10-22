module Profiles
  class Update
    include ImageUploads

    def self.call(user, updated_attributes = {})
      new(user, updated_attributes).call
    end

    attr_reader :error_message

    def initialize(user, updated_attributes)
      @user = user
      @profile = user.profile
      @updated_profile_attributes = updated_attributes[:profile] || {}
      @updated_user_attributes = updated_attributes[:user].to_h || {}
      @success = false
    end

    def call
      if verify_profile_image && update_profile
        @user.touch(:profile_updated_at)
        follow_hiring_tag
      else
        Honeycomb.add_field("error", @error_message)
        Honeycomb.add_field("errored", true)
      end
      self
    end

    def success?
      @success
    end

    private

    def verify_profile_image
      image = @updated_user_attributes[:profile_image]
      return true unless image
      return true if valid_image_file?(image) && valid_filename?(image)

      false
    end

    def valid_image_file?(image)
      return true if file?(image)

      @error_message = IS_NOT_FILE_MESSAGE
      false
    end

    def valid_filename?(image)
      return true unless long_filename?(image)

      @error_message = FILENAME_TOO_LONG_MESSAGE
      false
    end

    def update_profile
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
  end
end
