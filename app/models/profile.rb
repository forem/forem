class Profile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true

  # This method generates typed accessors for all profile fields
  def self.refresh_store_accessors!
    ProfileField.find_each do |field|
      store_attribute :data, field.attribute_name, field.type
    end
  end

  refresh_store_accessors!
end
