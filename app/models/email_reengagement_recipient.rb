# app/models/email_reengagement_recipient.rb
class EmailReengagementRecipient < ApplicationRecord
  belongs_to :user

  validates :campaign_key, presence: true
  validates :user_id, uniqueness: { scope: :campaign_key }

  scope :for_campaign, ->(key) { where(campaign_key: key) }
  scope :sent,         -> { where.not(sent_at: nil) }
  scope :unconfirmed,  -> { where(confirmed_at: nil) }
  scope :not_pruned,   -> { where(pruned_at: nil) }
end
