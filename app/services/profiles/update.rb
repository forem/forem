module Profiles
  module Update
    def self.call(profile, updated_attributes = {})
      # We don't update `data` directly. This uses the defined store_attributes
      # so we can make use of their typecasting.
      profile.assign_attributes(updated_attributes)

      # Before saving, filter out obsolete profile fields
      profile.data.slice!(*Profile.attributes)
      profile.save

      # Propagate changes back to the `users` table
      user_attributes = profile.data.transform_keys do |key|
        Profile::MAPPED_ATTRIBUTES.fetch(key, key).to_s
      end
      profile.user.update(user_attributes)
    end
  end
end
