require "rails_helper"

RSpec.describe NotificationSubscription, type: :model do
  subject { create(:notification_subscription, user: user, notifiable: article) }

  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }

  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(%i[notifiable_type notifiable_id]) }
end
