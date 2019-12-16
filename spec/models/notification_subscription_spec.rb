require "rails_helper"

RSpec.describe NotificationSubscription, type: :model do
  let_it_be(:user) { create(:user) }
  let_it_be(:article) { create(:article, user: user) }

  subject { create(:notification_subscription, user: user, notifiable: article) }

  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(%i[notifiable_type notifiable_id]) }
end
