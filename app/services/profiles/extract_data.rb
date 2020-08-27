module Profiles
  module ExtractData
    def self.call(user)
      user_attributes = user.attributes.symbolize_keys!

      mapped_attributes = Profile::MAPPED_ATTRIBUTES
      direct_attributes = Profile.attributes! - mapped_attributes.keys
      direct_data = user_attributes.extract!(*direct_attributes)
      mapped_data = mapped_attributes.keys.zip(user_attributes.values_at(*mapped_attributes.values)).to_h

      direct_data.merge(mapped_data)
    end
  end
end
