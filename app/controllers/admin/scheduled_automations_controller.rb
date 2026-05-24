module Admin
  class ScheduledAutomationsController < Admin::ApplicationController
    layout "admin"

    before_action :set_bot
    before_action :set_subforem
    before_action :set_automation, only: %i[show edit update destroy toggle_enabled]
    before_action :authorize_bot

    def index
      @automations = @bot.scheduled_automations.order(created_at: :desc)
    end

    def show
      # Show details of a specific automation
    end

    def new
      @automation = @bot.scheduled_automations.build
    end

  def create
    @automation = @bot.scheduled_automations.build(automation_params)

    if @automation.valid?
      # Calculate and set the next run time only if valid
      @automation.set_next_run_time!
      @automation.save!
      flash[:success] = "Scheduled automation created successfully!"
      redirect_to admin_subforem_community_bot_scheduled_automations_path(@subforem, @bot)
    else
      flash.now[:error] = @automation.errors.full_messages.join(", ")
      render :new
    end
  end

    def edit
      # Edit form for automation
    end

    def update
      # Recalculate next run time if frequency or config changed
      frequency_changed = automation_params[:frequency] != @automation.frequency
      config_changed = automation_params[:frequency_config] != @automation.frequency_config

      if @automation.update(automation_params)
        # Recalculate next run time if scheduling changed
        if frequency_changed || config_changed
          @automation.update!(next_run_at: @automation.calculate_next_run_time)
        end

        flash[:success] = "Scheduled automation updated successfully!"
        redirect_to admin_subforem_community_bot_scheduled_automations_path(@subforem, @bot)
      else
        flash.now[:error] = @automation.errors.full_messages.join(", ")
        render :edit
      end
    end

    def destroy
      if @automation.destroy
        flash[:success] = "Scheduled automation deleted successfully!"
      else
        flash[:error] = "Failed to delete automation"
      end

      redirect_to admin_subforem_community_bot_scheduled_automations_path(@subforem, @bot)
    end

    def toggle_enabled
      @automation.update!(enabled: !@automation.enabled)
      
      status = @automation.enabled? ? "enabled" : "disabled"
      flash[:success] = "Automation #{status} successfully!"
      
      redirect_to admin_subforem_community_bot_scheduled_automations_path(@subforem, @bot)
    end

    private

    def set_bot
      @bot = User.find(params[:community_bot_id])
    end

    def set_subforem
      @subforem = Subforem.find(params[:subforem_id])
    end

    def set_automation
      @automation = @bot.scheduled_automations.find(params[:id])
    end

    def authorize_bot
      authorize @bot, policy_class: CommunityBotPolicy
    end

    def automation_params
      params.require(:scheduled_automation).permit(
        :frequency,
        :action,
        :service_name,
        :additional_instructions,
        :enabled,
        frequency_config: {},
        action_config: {}
      )
    end

    protected

    def authorization_resource
      User
    end
  end
end

