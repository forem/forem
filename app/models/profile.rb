#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
class Profile < ApplicationRecord
  belongs_to :user

  store_accessor :data, :social_image

  after_commit :bust_user_profile_details_cache, on: :update, if: :profile_details_changed_for_cache?
  after_commit :enqueue_profile_spam_check, on: :update, if: :profile_spam_check_triggered?

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
    super unless match

    field = ProfileField.find_by(attribute_name: match[:attribute_name])
    super unless field

    self.class.instance_eval do
      store_accessor :data, field.attribute_name.to_sym
    end
    public_send(method_name, *args, **kwargs, &block)
  end

  # Defining this is not only a good practice in general, it's also necessary
  # for `update` to work since the `_assign_attribute` helper it uses performs
  # an explicit `responds_to?` check.
  def respond_to_missing?(method_name, include_private = false)
    match = method_name.match(ATTRIBUTE_NAME_REGEX)
    return true if match && match[:attribute_name].in?(self.class.attributes)

    super
  end

  private

  def bust_user_profile_details_cache
    Users::BustProfileDetailsCacheWorker.perform_async(user_id)
  end

  def profile_details_changed_for_cache?
    saved_change_to_summary? ||
      saved_change_to_location? ||
      saved_change_to_website_url? ||
      saved_change_to_attribute?(:social_image) ||
      saved_change_to_data?
  end

  def profile_spam_check_triggered?
    saved_change_to_website_url? || summary_contains_spam_trigger_terms?
  end

  def summary_contains_spam_trigger_terms?
    return false unless saved_change_to_summary?

    Spam::Handler.profile_spam_trigger_term_match?(summary)
  end

  def enqueue_profile_spam_check
    Users::HandleProfileSpamWorker.perform_async(user_id)
  end
end
