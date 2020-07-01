module UserSubscriptionSourceable
  extend ActiveSupport::Concern

  # This all assumes there's an association with User under the column user_id.

  included do
    has_many :user_subscriptions, as: :user_subscription_sourceable
    has_many :sourced_subscribers,
             class_name: "User",
             through: :user_subscriptions,
             source: :subscriber,
             foreign_key: :user_id
  end

  def build_user_subscription(subscriber, subscriber_email: nil)
    UserSubscription.new(user_subscription_attributes(subscriber, subscriber_email))
  end

  def create_user_subscription(subscriber, subscriber_email: nil)
    UserSubscription.create(user_subscription_attributes(subscriber, subscriber_email))
  end

  private

  # We explicitly pass in a subscriber_email when creating subscriptions from
  # the front end to ensure the email matches the subscriber's current email
  # address. See #subscriber_email_mismatch? validation on the UserSubscription
  # model.
  def user_subscription_attributes(subscriber, subscriber_email)
    {
      user_subscription_sourceable: self,
      author_id: user_id,
      subscriber_id: subscriber&.id,
      subscriber_email: subscriber_email || subscriber&.email
    }
  end
end
