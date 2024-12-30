class Email < ApplicationRecord
  belongs_to :audience_segment, optional: true
  has_many :email_messages

  after_save :deliver_to_users

  validates :subject, presence: true
  validates :body, presence: true

  enum type_of: { one_off: 0, newsletter: 1, onboarding_drip: 2 }
  enum status: { draft: 0, active: 1, delivered: 2 } # Not implemented yet anywhere

  attr_accessor :test_email_addresses

  def self.replace_merge_tags(content, user)
    return content unless user
  
    # Define the mapping of merge tags to user attributes
    merge_tags = {
      "name" => user.name,
      "username" => user.username,
      "email" => user.email
    }
  
    # Replace merge tags in the content
    content.gsub(/\*\|(\w+)\|\*/) do |match|
      tag = Regexp.last_match(1).downcase
      merge_tags[tag] || match # Leave the tag untouched if not found
    end
  end

  def bg_color
    case status
    when "draft"
      # soft yellow hex
      "#fff9c0"
    when "active"
      # soft green hex
      "#d4f7dc"
    when "delivered"
      # soft blue hex
      "#d4e7f7"
    end
  end

  def default_from_name_based_on_type
    case type_of
    when "one_off"
      ""
    when "newsletter"
      "Newsletter"
    when "onboarding_drip"
      "Onboarding"
    end
  end

  def deliver_to_test_emails(addresses_string)
    addresses_string ||= test_email_addresses
    return if addresses_string.blank?

    email_array = addresses_string.gsub(/\s+/, "").split(",")
    users_batch = User.where(email: email_array)
    return if users_batch.empty?

    Emails::BatchCustomSendWorker.perform_async(users_batch.map(&:id), subject, body, type_of, id)
  end

  def deliver_to_users
    return if type_of == "onboarding_drip"
    return if status != "active"

    Emails::EnqueueCustomBatchSendWorker.perform_async(self.id)
    self.update_columns(status: "delivered")
  end
end
