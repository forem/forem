require "rails_helper"

RSpec.describe NotificationSubscriptions::Unsubscribe, type: :service do
  let(:current_user) { create(:user) }
  let(:another_user) { create(:user) }
  let(:article) { create(:article, user: current_user) }
  let!(:subscription) { create(:notification_subscription, user: current_user, notifiable: article) }

  describe "#call" do
    context "when a valid subscription ID is provided" do
      let(:params) { { subscription_id: subscription.id } }

      it "destroys the notification subscription" do
        expect do
          described_class.call(current_user, params)
        end.to change(NotificationSubscription, :count).by(-1)

        expect(NotificationSubscription.find_by(id: subscription.id)).to be_nil
      end

      it "returns the destroyed status" do
        result = described_class.call(current_user, params)
        expect(result).to eq({ destroyed: true })
      end
    end

    context "when an invalid subscription ID is provided" do
      let(:params) { { subscription_id: 9999 } }

      it "does not destroy any notification subscriptions" do
        expect do
          described_class.call(current_user, params)
        end.not_to change(NotificationSubscription, :count)
      end

      it "returns an error message" do
        result = described_class.call(current_user, params)
        expect(result).to eq({ errors: "Notification subscription not found" })
      end
    end

    context "when no subscription ID is provided" do
      let(:params) { {} }

      it "does not destroy any notification subscriptions" do
        expect do
          described_class.call(current_user, params)
        end.not_to change(NotificationSubscription, :count)
      end

      it "returns an error message" do
        result = described_class.call(current_user, params)
        expect(result).to eq({ errors: "Subscription ID is missing" })
      end
    end
  end
end
