require "rails_helper"

RSpec.describe Admin::ScheduledAutomationsController do
  let(:admin) { create(:user, :super_admin) }
  let(:subforem) { create(:subforem) }
  let(:bot) { create(:user, type_of: :community_bot) }
  let(:automation) { create(:scheduled_automation, user: bot) }

  before do
    sign_in admin
  end

  describe "GET #index" do
    it "returns success" do
      get admin_subforem_community_bot_scheduled_automations_path(subforem, bot)
      expect(response).to have_http_status(:success)
    end

    it "assigns automations" do
      automation # Create the automation
      get admin_subforem_community_bot_scheduled_automations_path(subforem, bot)
      expect(assigns(:automations)).to include(automation)
    end
  end

  describe "GET #new" do
    it "returns success" do
      get new_admin_subforem_community_bot_scheduled_automation_path(subforem, bot)
      expect(response).to have_http_status(:success)
    end

    it "builds a new automation" do
      get new_admin_subforem_community_bot_scheduled_automation_path(subforem, bot)
      expect(assigns(:automation)).to be_a_new(ScheduledAutomation)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        scheduled_automation: {
          frequency: "daily",
          frequency_config: { hour: "9", minute: "0" },
          action: "create_draft",
          action_config: { repo_name: "forem/forem", days_ago: "7" },
          service_name: "github_repo_recap",
          additional_instructions: "Test instructions"
        }
      }
    end

    context "with valid parameters" do
      it "creates a new automation" do
        expect do
          post admin_subforem_community_bot_scheduled_automations_path(subforem, bot),
               params: valid_params
        end.to change(ScheduledAutomation, :count).by(1)
      end

      it "sets the next_run_at" do
        post admin_subforem_community_bot_scheduled_automations_path(subforem, bot),
             params: valid_params
        automation = ScheduledAutomation.last
        expect(automation.next_run_at).to be_present
      end

      it "redirects to index" do
        post admin_subforem_community_bot_scheduled_automations_path(subforem, bot),
             params: valid_params
        expect(response).to redirect_to(
          admin_subforem_community_bot_scheduled_automations_path(subforem, bot)
        )
      end

      it "sets a success flash message" do
        post admin_subforem_community_bot_scheduled_automations_path(subforem, bot),
             params: valid_params
        expect(flash[:success]).to eq("Scheduled automation created successfully!")
      end

      it "handles string values in frequency_config by normalizing them to integers" do
        post admin_subforem_community_bot_scheduled_automations_path(subforem, bot),
             params: valid_params
        automation = ScheduledAutomation.last
        expect(automation.frequency_config["hour"]).to eq(9)
        expect(automation.frequency_config["minute"]).to eq(0)
        expect(automation.next_run_at).to be_present # Should calculate correctly with normalized integers
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          scheduled_automation: {
            frequency: "daily",
            frequency_config: {}, # Missing required hour and minute
            action: "create_draft",
            service_name: "github_repo_recap"
          }
        }
      end

      it "does not create a new automation" do
        expect do
          post admin_subforem_community_bot_scheduled_automations_path(subforem, bot),
               params: invalid_params
        end.not_to change(ScheduledAutomation, :count)
      end

      it "renders new template" do
        post admin_subforem_community_bot_scheduled_automations_path(subforem, bot),
             params: invalid_params
        expect(response).to render_template(:new)
      end

      it "sets an error flash message" do
        post admin_subforem_community_bot_scheduled_automations_path(subforem, bot),
             params: invalid_params
        expect(flash.now[:error]).to be_present
      end
    end

    context "with weekly frequency" do
      let(:weekly_params) do
        {
          scheduled_automation: {
            frequency: "weekly",
            frequency_config: { day_of_week: "5", hour: "9", minute: "0" },
            action: "create_draft",
            action_config: { repo_name: "forem/forem", days_ago: "7" },
            service_name: "github_repo_recap"
          }
        }
      end

      it "creates automation with correct next_run_at" do
        post admin_subforem_community_bot_scheduled_automations_path(subforem, bot),
             params: weekly_params
        automation = ScheduledAutomation.last
        expect(automation.next_run_at).to be_present
        expect(automation.next_run_at.wday).to eq(5) # Friday
      end
    end
  end

  describe "GET #edit" do
    it "returns success" do
      get edit_admin_subforem_community_bot_scheduled_automation_path(subforem, bot, automation)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH #update" do
    let(:update_params) do
      {
        scheduled_automation: {
          frequency: "hourly",
          frequency_config: { minute: "30" },
          additional_instructions: "Updated instructions"
        }
      }
    end

    context "with valid parameters" do
      it "updates the automation" do
        patch admin_subforem_community_bot_scheduled_automation_path(subforem, bot, automation),
              params: update_params
        automation.reload
        expect(automation.frequency).to eq("hourly")
        expect(automation.additional_instructions).to eq("Updated instructions")
      end

      it "recalculates next_run_at when frequency changes" do
        original_next_run = automation.next_run_at
        patch admin_subforem_community_bot_scheduled_automation_path(subforem, bot, automation),
              params: update_params
        automation.reload
        expect(automation.next_run_at).not_to eq(original_next_run)
      end

      it "redirects to index" do
        patch admin_subforem_community_bot_scheduled_automation_path(subforem, bot, automation),
              params: update_params
        expect(response).to redirect_to(
          admin_subforem_community_bot_scheduled_automations_path(subforem, bot)
        )
      end

      it "sets a success flash message" do
        patch admin_subforem_community_bot_scheduled_automation_path(subforem, bot, automation),
              params: update_params
        expect(flash[:success]).to eq("Scheduled automation updated successfully!")
      end
    end

    context "when only additional_instructions change" do
      let(:non_frequency_params) do
        {
          scheduled_automation: {
            additional_instructions: "Different instructions"
          }
        }
      end

      it "does not recalculate next_run_at" do
        original_next_run_at = 3.days.from_now.change(usec: 0)
        automation.update_column(:next_run_at, original_next_run_at)

        patch admin_subforem_community_bot_scheduled_automation_path(subforem, bot, automation),
              params: non_frequency_params

        expect(automation.reload.additional_instructions).to eq("Different instructions")
        expect(automation.next_run_at).to eq(original_next_run_at)
      end

      it "does not postpone an overdue run when the form resubmits the unchanged schedule as strings" do
        overdue_next_run_at = 5.minutes.ago.change(usec: 0)
        automation.update_column(:next_run_at, overdue_next_run_at)

        patch admin_subforem_community_bot_scheduled_automation_path(subforem, bot, automation),
              params: {
                scheduled_automation: {
                  frequency: "daily",
                  frequency_config: { hour: "9", minute: "0" },
                  additional_instructions: "Different instructions"
                }
              }

        expect(automation.reload.additional_instructions).to eq("Different instructions")
        expect(automation.next_run_at).to eq(overdue_next_run_at)
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          scheduled_automation: {
            frequency: "hourly",
            frequency_config: { minute: "999" } # Invalid minute
          }
        }
      end

      it "does not update the automation" do
        original_frequency = automation.frequency
        patch admin_subforem_community_bot_scheduled_automation_path(subforem, bot, automation),
              params: invalid_params
        automation.reload
        expect(automation.frequency).to eq(original_frequency)
      end

      it "renders edit template" do
        patch admin_subforem_community_bot_scheduled_automation_path(subforem, bot, automation),
              params: invalid_params
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the automation" do
      automation # Create the automation first
      expect do
        delete admin_subforem_community_bot_scheduled_automation_path(subforem, bot, automation)
      end.to change(ScheduledAutomation, :count).by(-1)
    end

    it "redirects to index" do
      delete admin_subforem_community_bot_scheduled_automation_path(subforem, bot, automation)
      expect(response).to redirect_to(
        admin_subforem_community_bot_scheduled_automations_path(subforem, bot)
      )
    end

    it "sets a success flash message" do
      delete admin_subforem_community_bot_scheduled_automation_path(subforem, bot, automation)
      expect(flash[:success]).to eq("Scheduled automation deleted successfully!")
    end
  end

  describe "PATCH #toggle_enabled" do
    let(:toggle_path) do
      toggle_enabled_admin_subforem_community_bot_scheduled_automation_path(subforem, bot, automation)
    end

    it "disables the automation" do
      automation.update_column(:enabled, true)
      patch toggle_path
      expect(automation.reload.enabled).to be(false)
      expect(flash[:success]).to eq("Automation disabled successfully!")
    end

    it "enables the automation" do
      automation.update_column(:enabled, false)
      patch toggle_path
      expect(automation.reload.enabled).to be(true)
      expect(flash[:success]).to eq("Automation enabled successfully!")
    end

    it "redirects to index" do
      patch toggle_path
      expect(response).to redirect_to(admin_subforem_community_bot_scheduled_automations_path(subforem, bot))
    end
  end
end

