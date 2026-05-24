require "rails_helper"

RSpec.describe Admin::BadgeAutomationsController do
  let(:admin) { create(:user, :super_admin) }
  let(:badge) { create(:badge, slug: "first-org-post", title: "First Org Post") }
  let(:organization) { create(:organization) }
  let(:automation) do
    create(:scheduled_automation,
           user: admin,
           action: "award_first_org_post_badge",
           service_name: "first_org_post_badge",
           action_config: {
             "badge_slug" => badge.slug,
             "organization_id" => organization.id
           },
           frequency: "daily",
           frequency_config: { "hour" => 9, "minute" => 0 })
  end

  before do
    sign_in admin
  end

  describe "GET #index" do
    it "returns success" do
      get admin_badge_badge_automations_path(badge)
      expect(response).to have_http_status(:success)
    end

    it "assigns the badge" do
      get admin_badge_badge_automations_path(badge)
      expect(assigns(:badge)).to eq(badge)
    end

    it "lists automations for the badge" do
      automation # Create the automation
      get admin_badge_badge_automations_path(badge)
      expect(assigns(:automations)).to include(automation)
    end

    it "only shows automations for this specific badge" do
      other_badge = create(:badge, slug: "other-badge")
      other_automation = create(:scheduled_automation,
                                user: admin,
                                action: "award_first_org_post_badge",
                                action_config: {
                                  "badge_slug" => other_badge.slug,
                                  "organization_id" => organization.id
                                })
      automation # Create automation for the badge we're viewing

      get admin_badge_badge_automations_path(badge)
      expect(assigns(:automations)).to include(automation)
      expect(assigns(:automations)).not_to include(other_automation)
    end
  end

  describe "GET #new" do
    it "returns success" do
      get new_admin_badge_badge_automation_path(badge)
      expect(response).to have_http_status(:success)
    end

    it "assigns the badge" do
      get new_admin_badge_badge_automation_path(badge)
      expect(assigns(:badge)).to eq(badge)
    end

    it "builds a new automation with correct defaults" do
      get new_admin_badge_badge_automation_path(badge)
      new_automation = assigns(:automation)
      expect(new_automation).to be_a_new(ScheduledAutomation)
      expect(new_automation.action).to eq("award_first_org_post_badge")
      expect(new_automation.service_name).to eq("first_org_post_badge")
      expect(new_automation.action_config["badge_slug"]).to eq(badge.slug)
      expect(new_automation.frequency).to eq("daily")
      expect(new_automation.enabled).to be(true)
    end

    it "assigns organizations" do
      org1 = create(:organization, name: "Org 1")
      org2 = create(:organization, name: "Org 2")
      get new_admin_badge_badge_automation_path(badge)
      expect(assigns(:organizations)).to include(org1, org2)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        scheduled_automation: {
          frequency: "daily",
          frequency_config: { "hour" => 10, "minute" => 30 },
          enabled: true
        },
        organization_id: organization.id
      }
    end

    context "with valid parameters" do
      it "creates a new automation" do
        expect {
          post admin_badge_badge_automations_path(badge), params: valid_params
        }.to change(ScheduledAutomation, :count).by(1)
      end

      it "assigns the current user as the automation user" do
        post admin_badge_badge_automations_path(badge), params: valid_params
        created_automation = ScheduledAutomation.last
        expect(created_automation.user).to eq(admin)
      end

      it "sets the correct action and service_name" do
        post admin_badge_badge_automations_path(badge), params: valid_params
        created_automation = ScheduledAutomation.last
        expect(created_automation.action).to eq("award_first_org_post_badge")
        expect(created_automation.service_name).to eq("first_org_post_badge")
      end

      it "sets the badge_slug in action_config" do
        post admin_badge_badge_automations_path(badge), params: valid_params
        created_automation = ScheduledAutomation.last
        expect(created_automation.action_config["badge_slug"]).to eq(badge.slug)
      end

      it "sets the organization_id in action_config" do
        post admin_badge_badge_automations_path(badge), params: valid_params
        created_automation = ScheduledAutomation.last
        expect(created_automation.action_config["organization_id"]).to eq(organization.id.to_s)
      end

      it "sets the next_run_at" do
        post admin_badge_badge_automations_path(badge), params: valid_params
        created_automation = ScheduledAutomation.last
        expect(created_automation.next_run_at).to be_present
      end

      it "redirects to the index page" do
        post admin_badge_badge_automations_path(badge), params: valid_params
        expect(response).to redirect_to(admin_badge_badge_automations_path(badge))
      end

      it "shows a success message" do
        post admin_badge_badge_automations_path(badge), params: valid_params
        expect(flash[:success]).to be_present
      end
    end

    context "with invalid parameters" do
      it "does not create an automation without organization" do
        invalid_params = valid_params.dup
        invalid_params[:organization_id] = nil

        expect {
          post admin_badge_badge_automations_path(badge), params: invalid_params
        }.not_to change(ScheduledAutomation, :count)
      end

      it "renders the new template with errors" do
        invalid_params = valid_params.dup
        invalid_params[:scheduled_automation][:frequency] = nil

        post admin_badge_badge_automations_path(badge), params: invalid_params
        expect(response).to render_template(:new)
        expect(assigns(:automation).errors).to be_present
      end
    end

    context "with different frequency types" do
      it "creates an hourly automation" do
        params = valid_params.dup
        params[:scheduled_automation][:frequency] = "hourly"
        params[:scheduled_automation][:frequency_config] = { "minute" => 15 }

        post admin_badge_badge_automations_path(badge), params: params
        created_automation = ScheduledAutomation.last
        expect(created_automation.frequency).to eq("hourly")
        expect(created_automation.frequency_config["minute"]).to eq(15)
      end

      it "creates a weekly automation" do
        params = valid_params.dup
        params[:scheduled_automation][:frequency] = "weekly"
        params[:scheduled_automation][:frequency_config] = { "day_of_week" => 5, "hour" => 9, "minute" => 0 }

        post admin_badge_badge_automations_path(badge), params: params
        created_automation = ScheduledAutomation.last
        expect(created_automation.frequency).to eq("weekly")
        expect(created_automation.frequency_config["day_of_week"]).to eq(5)
      end
    end
  end

  describe "GET #edit" do
    it "returns success" do
      get edit_admin_badge_badge_automation_path(badge, automation)
      expect(response).to have_http_status(:success)
    end

    it "assigns the automation" do
      get edit_admin_badge_badge_automation_path(badge, automation)
      expect(assigns(:automation)).to eq(automation)
    end

    it "raises error if automation doesn't belong to badge" do
      other_badge = create(:badge)
      other_automation = create(:scheduled_automation,
                                user: admin,
                                action: "award_first_org_post_badge",
                                action_config: {
                                  "badge_slug" => other_badge.slug
                                })

      expect {
        get edit_admin_badge_badge_automation_path(badge, other_automation)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "PATCH #update" do
    let(:update_params) do
      {
        scheduled_automation: {
          frequency: "weekly",
          frequency_config: { "day_of_week" => 1, "hour" => 14, "minute" => 0 },
          enabled: false
        },
        organization_id: organization.id
      }
    end

    context "with valid parameters" do
      it "updates the automation" do
        patch admin_badge_badge_automation_path(badge, automation), params: update_params
        automation.reload
        expect(automation.frequency).to eq("weekly")
        expect(automation.enabled).to be(false)
      end

      it "updates the organization_id" do
        new_org = create(:organization)
        params = update_params.dup
        params[:organization_id] = new_org.id

        patch admin_badge_badge_automation_path(badge, automation), params: params
        automation.reload
        expect(automation.action_config["organization_id"]).to eq(new_org.id.to_s)
      end

      it "preserves the badge_slug" do
        patch admin_badge_badge_automation_path(badge, automation), params: update_params
        automation.reload
        expect(automation.action_config["badge_slug"]).to eq(badge.slug)
      end

      it "does not change the user" do
        original_user = automation.user
        patch admin_badge_badge_automation_path(badge, automation), params: update_params
        automation.reload
        expect(automation.user).to eq(original_user)
      end

      it "recalculates next_run_at when frequency changes" do
        original_next_run = automation.next_run_at
        patch admin_badge_badge_automation_path(badge, automation), params: update_params
        automation.reload
        expect(automation.next_run_at).not_to eq(original_next_run)
      end

      it "redirects to the index page" do
        patch admin_badge_badge_automation_path(badge, automation), params: update_params
        expect(response).to redirect_to(admin_badge_badge_automations_path(badge))
      end

      it "shows a success message" do
        patch admin_badge_badge_automation_path(badge, automation), params: update_params
        expect(flash[:success]).to be_present
      end
    end

    context "with invalid parameters" do
      it "renders the edit template with errors" do
        invalid_params = update_params.dup
        invalid_params[:scheduled_automation][:frequency] = nil

        patch admin_badge_badge_automation_path(badge, automation), params: invalid_params
        expect(response).to render_template(:edit)
        expect(assigns(:automation).errors).to be_present
      end
    end
  end

  describe "DELETE #destroy" do
    it "deletes the automation" do
      automation # Create the automation
      expect {
        delete admin_badge_badge_automation_path(badge, automation)
      }.to change(ScheduledAutomation, :count).by(-1)
    end

    it "redirects to the index page" do
      delete admin_badge_badge_automation_path(badge, automation)
      expect(response).to redirect_to(admin_badge_badge_automations_path(badge))
    end

    it "shows a success message" do
      delete admin_badge_badge_automation_path(badge, automation)
      expect(flash[:success]).to be_present
    end
  end

  describe "PATCH #toggle_enabled" do
    it "toggles enabled status" do
      automation.update!(enabled: true)
      patch toggle_enabled_admin_badge_badge_automation_path(badge, automation)
      automation.reload
      expect(automation.enabled).to be(false)
    end

    it "redirects to the index page" do
      patch toggle_enabled_admin_badge_badge_automation_path(badge, automation)
      expect(response).to redirect_to(admin_badge_badge_automations_path(badge))
    end

    it "shows a success message" do
      patch toggle_enabled_admin_badge_badge_automation_path(badge, automation)
      expect(flash[:success]).to be_present
    end
  end

  describe "authorization" do
    context "when user is not an admin" do
      let(:regular_user) { create(:user) }

      before do
        sign_in regular_user
      end

      it "denies access to index" do
        expect {
          get admin_badge_badge_automations_path(badge)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end

