require "rails_helper"

RSpec.describe "Pro Memberships", type: :request do
  describe "GET /pro" do
    it "returns Pro landing page" do
      get pro_membership_path
      expect(response.body).to include("Like a Pro")
    end
  end

  describe "POST /pro" do
    let(:user) { create(:user) }

    context "when the user is not logged in" do
      it "redirects to the sign up page" do
        post pro_membership_path
        expect(response).to redirect_to(sign_up_path)
      end
    end

    context "when the user is logged in and already has a pro memberships" do
      before do
        sign_in user
      end

      it "does not authorize creation if it has an active membership" do
        create(:pro_membership, user: user)
        expect do
          post pro_membership_path
        end.to raise_error(Pundit::NotAuthorizedError)
      end

      it "does not authorize creation if it has an expired membership" do
        Timecop.freeze(Time.current) do
          membership = create(:pro_membership, user: user)
          membership.expire!

          expect do
            post pro_membership_path
          end.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      it "does not authorize creation if the user as a pro role" do
        user.add_role(:pro)
        expect do
          post pro_membership_path
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when the user is logged in without a pro membership and enough credits" do
      before do
        sign_in user
        create_list(:credit, ProMembership::MONTHLY_COST, user: user)
      end

      it "creates an active pro membership" do
        expect do
          post pro_membership_path
        end.to change(ProMembership, :count).by(1)
        expect(user.reload.pro_membership.active?).to be(true)
      end

      it "buys the pro membership with the correct amount of credits" do
        expect do
          post pro_membership_path
        end.to change(user.credits.spent, :count).by(ProMembership::MONTHLY_COST)
      end

      it "enqueues a job to bust the user's cache" do
        ActiveJob::Base.queue_adapter.enqueued_jobs.clear # make sure it hasn't been previously queued
        sidekiq_assert_enqueued_with(job: Users::BustCacheWorker, args: [user.id]) do
          post pro_membership_path
        end
      end

      it "enqueues a job to bust the user's articles caches" do
        sidekiq_assert_enqueued_with(
          job: Users::ResaveArticlesWorker,
          args: [user.id],
          queue: "medium_priority",
        ) do
          post pro_membership_path
        end
      end

      it "adds the user to the pro members channel" do
        create(:chat_channel, channel_type: "invite_only", slug: "pro-members")
        post pro_membership_path
        expect(user.reload.chat_channels.exists?(slug: "pro-members")).to be(true)
      end

      it "redirects to the pro membership settings page with a notice" do
        post pro_membership_path
        expect(response).to redirect_to(user_settings_path("pro-membership"))
        expect(flash[:settings_notice]).to eq("You are now a Pro!")
      end
    end

    context "when the user is logged in without a pro membership and not enough credits" do
      before do
        sign_in user
      end

      it "does not create an active pro membership" do
        expect do
          post pro_membership_path
        end.to change(ProMembership, :count).by(0)
      end

      it "does not subtract credits" do
        expect do
          post pro_membership_path
        end.to change(user.credits.spent, :count).by(0)
      end

      it "redirects to the pro membership settings page with an error message" do
        post pro_membership_path
        expect(response).to redirect_to(user_settings_path("pro-membership"))
        expect(flash[:error]).to eq("You don't have enough credits!")
      end
    end
  end

  describe "PUT /pro" do
    let(:user) { create(:user) }

    context "when the user is not logged in" do
      it "redirects to the sign up page" do
        put pro_membership_path
        expect(response).to redirect_to(sign_up_path)
      end
    end

    context "when the user is logged in without a pro membership" do
      before do
        sign_in user
      end

      it "does not authorize the operation" do
        expect do
          put pro_membership_path
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when the user is logged in with a pro membership" do
      before do
        sign_in user
      end

      it "works correctly" do
        create(:pro_membership, user: user)
        put pro_membership_path, params: { pro_membership: { auto_recharge: true } }
        expect(flash[:settings_notice]).to eq("Your membership has been updated!")
        expect(response).to redirect_to(user_settings_path("pro-membership"))
      end

      it "activates auto recharge" do
        pro_membership = create(:pro_membership, user: user)
        put pro_membership_path, params: { pro_membership: { auto_recharge: true } }
        expect(pro_membership.reload.auto_recharge).to be(true)
      end

      it "deactivates auto recharge" do
        pro_membership = create(:pro_membership, user: user, auto_recharge: true)
        put pro_membership_path, params: { pro_membership: { auto_recharge: false } }
        expect(pro_membership.reload.auto_recharge).to be(false)
      end
    end
  end
end
