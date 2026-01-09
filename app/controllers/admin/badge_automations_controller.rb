module Admin
  class BadgeAutomationsController < Admin::ApplicationController
    layout "admin"
    helper ScheduledAutomationsHelper

    before_action :set_badge
    before_action :set_automation, only: %i[show edit update destroy toggle_enabled]
    before_action :set_organizations

    def index
      @automations = ScheduledAutomation
                      .where(action: "award_first_org_post_badge")
                      .where("action_config->>'badge_slug' = ?", @badge.slug)
                      .includes(:user)
                      .order(created_at: :desc)
    end

    def new
      @automation = ScheduledAutomation.new(
        action: "award_first_org_post_badge",
        service_name: "first_org_post_badge",
        action_config: {
          "badge_slug" => @badge.slug
        },
        frequency: "daily",
        frequency_config: { "hour" => 9, "minute" => 0 },
        enabled: true
      )
    end

    def create
      @automation = ScheduledAutomation.new(automation_params)
      @automation.action = "award_first_org_post_badge"
      @automation.service_name = "first_org_post_badge"
      @automation.user = current_user # Automatically assign to current admin user
      @automation.action_config ||= {}
      @automation.action_config["badge_slug"] = @badge.slug
      
      # Ensure organization_id is set from params
      if params[:organization_id].present?
        @automation.action_config["organization_id"] = params[:organization_id]
      else
        @automation.errors.add(:base, "Organization is required")
      end

      if @automation.errors.empty? && @automation.valid?
        @automation.set_next_run_time!
        @automation.save!
        flash[:success] = "Badge automation created successfully!"
        redirect_to admin_badge_badge_automations_path(@badge)
      else
        flash.now[:error] = @automation.errors.full_messages.join(", ")
        render :new
      end
    end

    def edit
      # Edit form for automation
    end

    def update
      frequency_changed = automation_params[:frequency] != @automation.frequency
      config_changed = automation_params[:frequency_config] != @automation.frequency_config

      # Remove user_id from params if present (we don't allow changing the user)
      update_params = automation_params.except(:user_id)

      if @automation.update(update_params)
        # Ensure badge_slug stays in action_config
        @automation.action_config ||= {}
        @automation.action_config["badge_slug"] = @badge.slug
        
        # Update organization_id if provided
        if params[:organization_id].present?
          @automation.action_config["organization_id"] = params[:organization_id]
        end
        
        @automation.save!

        # Recalculate next run time if scheduling changed
        if frequency_changed || config_changed
          @automation.update!(next_run_at: @automation.calculate_next_run_time)
        end

        flash[:success] = "Badge automation updated successfully!"
        redirect_to admin_badge_badge_automations_path(@badge)
      else
        flash.now[:error] = @automation.errors.full_messages.join(", ")
        render :edit
      end
    end

    def destroy
      if @automation.destroy
        flash[:success] = "Badge automation deleted successfully!"
      else
        flash[:error] = "Failed to delete automation"
      end

      redirect_to admin_badge_badge_automations_path(@badge)
    end

    def toggle_enabled
      @automation.update!(enabled: !@automation.enabled)

      status = @automation.enabled? ? "enabled" : "disabled"
      flash[:success] = "Automation #{status} successfully!"

      redirect_to admin_badge_badge_automations_path(@badge)
    end

    private

    def set_badge
      @badge = Badge.find(params[:badge_id])
    end

    def set_automation
      @automation = ScheduledAutomation.find(params[:id])
      # Ensure this automation belongs to the badge
      unless @automation.action_config&.dig("badge_slug") == @badge.slug
        raise ActiveRecord::RecordNotFound
      end
    end

    def set_organizations
      @organizations = Organization.order(name: :asc)
    end

    def automation_params
      permitted = params.require(:scheduled_automation).permit(
        :frequency,
        :additional_instructions,
        :enabled,
        frequency_config: {},
        action_config: {}
      )
      
      # Convert ActionController::Parameters to hash for nested attributes
      result = {
        frequency: permitted[:frequency],
        additional_instructions: permitted[:additional_instructions],
        enabled: permitted[:enabled],
        frequency_config: permitted[:frequency_config].present? ? permitted[:frequency_config].to_h : {},
        action_config: permitted[:action_config].present? ? permitted[:action_config].to_h : {}
      }
      
      # Handle organization_id from separate select field
      if params[:organization_id].present?
        result[:action_config] ||= {}
        result[:action_config]["organization_id"] = params[:organization_id]
      end
      
      result
    end

    protected

    # Override to use Badge for authorization instead of trying to find BadgeAutomation model
    def authorization_resource
      Badge
    end
  end
end

