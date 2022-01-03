require "rails_helper"

RSpec.describe "/admin/users/:user_id/tools/credits", type: :request do
  include_examples "Admin::Users::Tools::ShowAction", :admin_user_tools_credits_path,
                   Admin::Users::Tools::CreditsComponent

  describe "#create" do
    let(:user) { create(:user) }

    it "returns not found for non existing users" do
      expect { post admin_user_tools_credits_path(9999) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns :unprocessable_entity if a param is invalid", :aggregate_failures do
      expect do
        post admin_user_tools_credits_path(user), params: {
          credits: {
            count: :a
          }
        }, xhr: true
      end.to not_change(user.credits, :count)
        .and not_change(user.notes, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to be_present
    end

    it "adds credits to the user and a note", :aggregate_failures do
      expect do
        post admin_user_tools_credits_path(user), params: {
          credits: {
            count: 1,
            note: "Test"
          }
        }, xhr: true
      end.to change(user.credits, :count).by(1)
        .and change(user.notes, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "adds credits to the user's organization and a note", :aggregate_failures do
      membership = create(:organization_membership, user: user)

      expect do
        post admin_user_tools_credits_path(user), params: {
          credits: {
            count: 1,
            note: "Test",
            organization_id: membership.organization_id
          }
        }, xhr: true
      end.to change(membership.organization.credits, :count).by(1)
        .and change(user.notes, :count).by(1)
        .and not_change(user.credits, :count)

      expect(response).to have_http_status(:created)
    end

    it "returns a JSON result", :aggregate_failures do
      post admin_user_tools_credits_path(user), params: {
        credits: {
          count: 1,
          note: "Test"
        }
      }, xhr: true

      expect(response.media_type).to eq("application/json")
      expect(response.parsed_body["result"]).to be_present
    end
  end

  describe "#destroy" do
    let(:user) { create(:user) }

    it "returns not found for non existing users" do
      expect { delete admin_user_tools_credits_path(9999) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns :unprocessable_entity if a param is invalid", :aggregate_failures do
      expect do
        delete admin_user_tools_credits_path(user), params: {
          credits: {
            count: :a
          }
        }, xhr: true
      end.to not_change(user.credits, :count)
        .and not_change(user.notes, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to be_present
    end

    it "does not remove credits if none are available", :aggregate_failures do
      expect do
        delete admin_user_tools_credits_path(user), params: {
          credits: {
            count: 1,
            note: "Test"
          }
        }, xhr: true
      end.to change(user.credits, :count).by(0)
        .and change(user.notes, :count).by(1)

      expect(response).to have_http_status(:ok)
    end

    it "removes credits from the user and adds a note", :aggregate_failures do
      Credit.add_to(user, 1)

      expect do
        delete admin_user_tools_credits_path(user), params: {
          credits: {
            count: 1,
            note: "Test"
          }
        }, xhr: true
      end.to change(user.credits, :count).by(-1)
        .and change(user.notes, :count).by(1)

      expect(response).to have_http_status(:ok)
    end

    it "remove credits from the user's organization and adds a note", :aggregate_failures do
      organization = create(:organization_membership, user: user).organization
      Credit.add_to(organization, 1)

      expect do
        delete admin_user_tools_credits_path(user), params: {
          credits: {
            count: 1,
            note: "Test",
            organization_id: organization.id
          }
        }, xhr: true
      end.to change(organization.credits, :count).by(-1)
        .and change(user.notes, :count).by(1)
        .and not_change(user.credits, :count)

      expect(response).to have_http_status(:ok)
    end

    it "returns a JSON result", :aggregate_failures do
      delete admin_user_tools_credits_path(user), params: {
        credits: {
          count: 1,
          note: "Test"
        }
      }, xhr: true

      expect(response.media_type).to eq("application/json")
      expect(response.parsed_body["result"]).to be_present
    end
  end
end
