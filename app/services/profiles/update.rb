module Profiles
  module Update
    def self.call(profile, updated_attributes = {})
      # Explicitly assign attributes so we make use of store_attribute's typecasting
      updated_attributes.each { |key, value| profile.public_send("#{key}=", value) }

      # Only keep current profile fields
      profile.data.slice!(*Profile.stored_attributes[:data])

      profile.save
    end
  end
end
