require "rails_helper"

RSpec.describe ProMemberships::Biller, type: :service do
  def format_date(datetime)
    # PostgreSQL DATE(..) function uses UTC.
    datetime.utc.to_date.iso8601
  end

  context "when there are expiring memberships with enough credits" do
    let(:pro_membership) { create(:pro_membership) }
    let(:user) { pro_membership.user }

    before do
      create_list(:credit, ProMembership::MONTHLY_COST, user: user)
    end

    it "renews the membership" do
      Timecop.travel(format_date(pro_membership.expires_at)) do
        described_class.call
        pro_membership.reload
        expect(pro_membership.expires_at.to_i).to eq(1.month.from_now.to_i)
        expect(pro_membership.status).to eq("active")
      end
    end

    it "subtracts the correct amount of credits" do
      Timecop.travel(format_date(pro_membership.expires_at)) do
        expect do
          described_class.call
        end.to change(user.credits.spent, :size).by(ProMembership::MONTHLY_COST)
      end
    end

    it "adds the user back to the pro members chat channel" do
      create(:chat_channel, slug: "pro-members", channel_type: "invite_only")

      Timecop.travel(format_date(pro_membership.expires_at)) do
        described_class.call
        expect(user.reload.chat_channels.exists?(slug: "pro-members")).to be(true)
      end
    end

    it "does not fail if the user is already in the pro members chat channel" do
      cc = create(:chat_channel, slug: "pro-members", channel_type: "invite_only")
      cc.add_users(user)

      allow(Rails.logger).to receive(:error)
      Timecop.travel(format_date(pro_membership.expires_at)) do
        described_class.call
        expect(Rails.logger).not_to have_received(:error)
        expect(user.reload.chat_channels.exists?(slug: "pro-members")).to be(true)
      end
    end

    it "enqueues a job to bust the users caches" do
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear # make sure it hasn't been previously queued
      Timecop.travel(format_date(pro_membership.expires_at)) do
        sidekiq_assert_enqueued_with(job: Users::BustCacheWorker, args: [user.id]) do
          described_class.call
        end
      end
    end

    it "enqueues a job to bust the users articles caches" do
      Timecop.travel(format_date(pro_membership.expires_at)) do
        sidekiq_assert_enqueued_with(
          job: Users::ResaveArticlesWorker,
          args: [user.id],
          queue: "medium_priority",
        ) do
          described_class.call
        end
      end
    end

    context "when an error occurs" do
      it "does not renew the membership" do
        Timecop.travel(format_date(pro_membership.expires_at)) do
          pro_membership.expire!
          allow(Credits::Buyer).to receive(:call).and_raise(StandardError)
          described_class.call
          expect(pro_membership.expires_at.to_i).to be(Time.current.to_i)
          expect(pro_membership.status).to eq("expired")
        end
      end

      it "does not subtract credits" do
        Timecop.travel(format_date(pro_membership.expires_at)) do
          allow(Credits::Buyer).to receive(:call).and_raise(StandardError)
          expect do
            described_class.call
          end.to change(user.credits.spent, :size).by(0)
        end
      end

      it "notifies the admins about the error" do
        Timecop.travel(format_date(pro_membership.expires_at)) do
          allow(Credits::Buyer).to receive(:call).and_raise(StandardError)
          sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
            described_class.call
          end
        end
      end
    end
  end

  context "when there are expiring memberships with insufficient credits" do
    let(:pro_membership) { create(:pro_membership) }
    let(:user) { pro_membership.user }

    it "expires the membership" do
      Timecop.travel(format_date(pro_membership.expires_at)) do
        described_class.call
        pro_membership.reload
        expect(pro_membership.expired?).to be(true)
        expect(pro_membership.status).to eq("expired")
      end
    end

    it "removes the user from the pro members chat channel" do
      cc = create(:chat_channel, slug: "pro-members", channel_type: "invite_only")
      cc.add_users(user)

      Timecop.travel(format_date(pro_membership.expires_at)) do
        described_class.call
        expect(user.reload.chat_channels.exists?(slug: "pro-members")).to be(false)
      end
    end

    it "notifies the admins about the expiration" do
      Timecop.travel(format_date(pro_membership.expires_at)) do
        sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
          described_class.call
        end
      end
    end

    it "enqueues a job to bust the users caches" do
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear # make sure it hasn't been previously queued
      Timecop.travel(format_date(pro_membership.expires_at)) do
        sidekiq_assert_enqueued_with(job: Users::BustCacheWorker, args: [user.id]) do
          described_class.call
        end
      end
    end

    it "enqueues a job to bust the users articles caches" do
      Timecop.travel(format_date(pro_membership.expires_at)) do
        sidekiq_assert_enqueued_with(
          job: Users::ResaveArticlesWorker,
          args: [user.id],
          queue: "medium_priority",
        ) do
          described_class.call
        end
      end
    end
  end

  context "when there are expiring memberships with insufficient credits and auto recharge" do
    let(:pro_membership) { create(:pro_membership, auto_recharge: true) }
    let(:user) { pro_membership.user }

    context "when the user has an associated customer" do
      before do
        StripeMock.start
        customer = Payments::Customer.create
        user.update_columns(stripe_id_code: customer.id)
      end

      after do
        StripeMock.stop
      end

      it "charges the customer" do
        customer = Payments::Customer.get(user.stripe_id_code)
        allow(Payments::Customer).to receive(:charge)
        Timecop.travel(format_date(pro_membership.expires_at)) do
          described_class.call
        end

        expect(Payments::Customer).to have_received(:charge).with(
          customer: customer,
          amount: ProMembership::MONTHLY_COST_USD,
          description: "Purchase of 5 credits.",
        )
      end

      it "adds the correct amount of credits" do
        Timecop.travel(format_date(pro_membership.expires_at)) do
          # we cannot use "expect.to change" because of how activerecord-import works
          old_num_credits = user.credits.size
          described_class.call
          expect(user.reload.credits.size).to be(old_num_credits + ProMembership::MONTHLY_COST)
        end
      end

      it "renews the membership" do
        Timecop.travel(format_date(pro_membership.expires_at)) do
          described_class.call
          pro_membership.reload
          expect(pro_membership.expires_at.to_i).to eq(1.month.from_now.to_i)
          expect(pro_membership.status).to eq("active")
        end
      end

      it "spends the correct amount of credits" do
        Timecop.travel(format_date(pro_membership.expires_at)) do
          # we cannot use "expect.to change" because of how activerecord-import works
          old_num_credits = user.reload.credits.spent.size
          described_class.call
          expect(user.reload.credits.spent.size).to eq(old_num_credits + ProMembership::MONTHLY_COST)
        end
      end

      it "enqueues a job to bust the users caches" do
        ActiveJob::Base.queue_adapter.enqueued_jobs.clear # make sure it hasn't been previously queued
        Timecop.travel(format_date(pro_membership.expires_at)) do
          sidekiq_assert_enqueued_with(job: Users::BustCacheWorker, args: [user.id]) do
            described_class.call
          end
        end
      end

      it "enqueues a job to bust the users articles caches" do
        Timecop.travel(format_date(pro_membership.expires_at)) do
          sidekiq_assert_enqueued_with(
            job: Users::ResaveArticlesWorker,
            args: [user.id],
            queue: "medium_priority",
          ) do
            described_class.call
          end
        end
      end
    end

    context "when the user has no associated customer" do
      it "notifies the admins about the problem" do
        allow(user).to receive(:stripe_id_code).and_return(nil)
        Timecop.travel(format_date(pro_membership.expires_at)) do
          sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
            described_class.call
          end
        end
      end

      it "does not change the number of credits" do
        Timecop.travel(format_date(pro_membership.expires_at)) do
          expect do
            described_class.call
          end.to change(user.credits, :size).by(0)
        end
      end
    end
  end
end
