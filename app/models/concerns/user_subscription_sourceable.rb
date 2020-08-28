module UserSubscriptionSourceable
  extend ActiveSupport::Concern

  # This all assumes there's an association with User under the column user_id.

  included do
    has_many :user_subscriptions, as: :user_subscription_sourceable, dependent: :nullify
    has_many :sourced_subscribers,
             class_name: "User",
             through: :user_subscriptions,
             source: :subscriber,
             foreign_key: :user_id
  end

  def build_user_subscription(subscriber)
    UserSubscription.new(user_subscription_attributes(subscriber))
  end

  def create_user_subscription(subscriber)
    UserSubscription.create(user_subscription_attributes(subscriber))
  end

  private

  def user_subscription_attributes(subscriber)
    {
      user_subscription_sourceable: self,
      author_id: user_id,
      subscriber_id: subscriber&.id,
      subscriber_email: subscriber&.email
    }
  end
end
