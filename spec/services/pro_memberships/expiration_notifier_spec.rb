require "rails_helper"

RSpec.describe ProMemberships::ExpirationNotifier, type: :service do
  context "when there are expiring memberships with enough credits" do
    let(:pro_membership) { create(:pro_membership) }
    let(:user) { pro_membership.user }

    it "does not deliver an email to the user" do
      create_list(:credit, ProMembership::MONTHLY_COST, user: user)
      Timecop.travel(pro_membership.expires_at - 1.week) do
        assert_emails 0 do
          described_class.call(1.week.from_now)
        end
      end
    end
  end

  context "when there are expiring memberships with insufficient credits" do
    let(:pro_membership) { create(:pro_membership) }

    it "delivers an email to the user" do
      Timecop.travel(pro_membership.expires_at - 1.week) do
        assert_emails 1 do
          described_class.call(1.week.from_now)
        end
      end
    end

    it "sets the expiration notification datetime" do
      Timecop.freeze(pro_membership.expires_at - 1.week) do
        described_class.call(1.week.from_now)
        expect(pro_membership.reload.expiration_notification_at.to_i).to eq(Time.current.to_i)
      end
    end

    it "increments the notifications count" do
      Timecop.travel(pro_membership.expires_at - 1.week) do
        expect(pro_membership.expiration_notifications_count).to eq(0)
        described_class.call(1.week.from_now)
        expect(pro_membership.reload.expiration_notifications_count).to eq(1)
      end
    end

    it "enqueus a slack bot ping job" do
      Timecop.travel(pro_membership.expires_at - 1.week) do
        sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
          described_class.call(1.week.from_now)
        end
      end
    end
  end

  context "when there are expiring memberships with insufficient credits and auto recharge" do
    let(:pro_membership) { create(:pro_membership) }
    let(:user) { pro_membership.user }

    it "does not deliver an email to the user" do
      pro_membership.update_columns(auto_recharge: true)
      Timecop.travel(pro_membership.expires_at - 1.week) do
        assert_emails 0 do
          described_class.call(1.week.from_now)
        end
      end
    end
  end
end
