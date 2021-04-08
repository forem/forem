require "rails_helper"

RSpec.describe "OrganizationsDelete", type: :request do
  let(:user) { create(:user, :org_admin) }
  let(:org) { user.organizations.first }
  let(:org_id) { org.id }
  let(:user2) { create(:user) }

  describe "successful deleting" do
    before do
      sign_in user
    end

    it "schedules the worker to delete an org" do
      sidekiq_assert_enqueued_with(job: Organizations::DeleteWorker, args: [org_id, user.id]) do
        delete organization_path(org_id)
      end
    end

    it "has the correct flash after deleting an org" do
      delete organization_path(org_id)
      notice_text = "Your organization: \"#{org.name}\" deletion is scheduled. You'll be notified when it's deleted."
      expect(flash[:settings_notice]).to include(notice_text)
    end

    it "redirects after scheduling deleting an org" do
      delete organization_path(org_id)
      expect(response).to redirect_to(user_settings_path(:organization))
    end
  end

  describe "not deleting" do
    it "doesn't schedule when trying to delete by other user" do
      sign_in user2
      sidekiq_assert_not_enqueued_with(job: Organizations::DeleteWorker) do
        delete organization_path(org_id)
      end
    end

    it "redirects correctly when not scheduling" do
      sign_in user2
      delete organization_path(org_id)
      expect(flash[:error]).to include("Your organization was not deleted")
      expect(response).to redirect_to(user_settings_path(:organization, id: org_id))
    end

    it "doesn't schedule when an org has articles" do
      create(:article, organization_id: org_id)
      sign_in user
      sidekiq_assert_not_enqueued_with(job: Organizations::DeleteWorker) do
        delete organization_path(org_id)
      end
    end

    it "doesn't schedule when an org has other users" do
      create(:organization_membership, organization_id: org_id)
      sign_in user
      sidekiq_assert_not_enqueued_with(job: Organizations::DeleteWorker) do
        delete organization_path(org_id)
      end
    end
  end
end
