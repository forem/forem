class Profile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :location, :website_url, length: { maximum: 100 }
  validates :website_url, url: { allow_blank: true, no_local: true, schemes: %w[https http] }
  validates_with ProfileValidator

  ATTRIBUTE_NAME_REGEX = /(?<attribute_name>\w+)=?/
  CACHE_KEY = "profile/attributes".freeze
  # Static fields are columns on the profiles table; they have no relationship
  # to a ProfileField record. These are columns we can safely assume exist for
  # any profile on a given Forem.
  STATIC_FIELDS = %w[summary location website_url].freeze

  # Update the Rails cache with the currently available attributes.
  def self.refresh_attributes!
    Rails.cache.delete(CACHE_KEY)
    attributes
  end

  def self.attributes
    Rails.cache.fetch(CACHE_KEY, expires_in: 24.hours) do
      ProfileField.pluck(:attribute_name)
    end
  end

  def self.static_fields
    STATIC_FIELDS
  end

  def clear!
    update(data: {})
  end

  # Lazily add accessors for profile fields on first use
  def method_missing(method_name, *args, **kwargs, &block)
    match = method_name.match(ATTRIBUTE_NAME_REGEX)
    field = ProfileField.find_by(attribute_name: match[:attribute_name])
    super unless field

    self.class.instance_eval do
      store_attribute :data, field.attribute_name.to_sym, field.type
    end
    public_send(method_name, *args, **kwargs, &block)
  end

  # Defining this is not only a good practice in general, it's also necessary
  # for `update` to work since the `_assign_attribute` helper it uses performs
  # an explicit `responds_to?` check.
  def respond_to_missing?(method_name, include_private = false)
    match = method_name.match(ATTRIBUTE_NAME_REGEX)
    return true if match[:attribute_name].in?(self.class.attributes)

    super
  end
end
