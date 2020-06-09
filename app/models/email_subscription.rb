class EmailSubscription < ApplicationRecord
  belongs_to :email_subscribable, polymorphic: true
  belongs_to :subscriber, class_name: "User", foreign_key: :user_id, inverse_of: :email_subscriptions
end
