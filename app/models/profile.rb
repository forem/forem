class Profile < ApplicationRecord
  belongs_to :user

  # Automatically generate typed accessors for all active profile fields
  ProfileField.active.find_each do |field|
    store_attribute :data, field.attribute_name, field.type
  end
end
