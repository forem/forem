module Admin
  class CommunityBotsController < Admin::ApplicationController
    layout "admin"

    before_action :set_subforem, only: %i[index new create]
    before_action :set_bot, only: %i[show destroy]
    before_action :authorize_subforem, only: %i[index new create]
    before_action :authorize_bot, only: %i[show destroy]

    def index
      @community_bots = User.community_bots_for_subforem(@subforem.id)
        .includes(:api_secrets)
        .order(created_at: :desc)
    end

    def show
      @api_secrets = @bot.api_secrets.order(created_at: :desc)
    end

    def new
      @bot = User.new
    end

    def create
      result = CommunityBots::CreateBot.call(
        subforem_id: @subforem.id,
        name: bot_params[:name],
        created_by: current_user,
        username: bot_params[:username],
        profile_image: bot_params[:profile_image],
      )

      if result.success?
        flash[:success] = "Community bot '#{bot_params[:name]}' created successfully!"
        redirect_to admin_subforem_community_bots_path(@subforem)
      else
        flash.now[:error] = result.error_message
        @bot = User.new(bot_params)
        render :new
      end
    end

    def destroy
      result = CommunityBots::DeleteBot.call(
        bot_user: @bot,
        deleted_by: current_user,
      )

      if result.success?
        flash[:success] = "Community bot deleted successfully!"
      else
        flash[:error] = result.error_message
      end

      redirect_to admin_subforem_community_bots_path(@bot.onboarding_subforem_id)
    end

    private

    def set_subforem
      @subforem = Subforem.find(params[:subforem_id])
    end

    def set_bot
      @bot = User.find(params[:id])
      @subforem = Subforem.find(@bot.onboarding_subforem_id)
    end

    def authorize_subforem
      authorize @subforem, policy_class: CommunityBotPolicy
    end

    def authorize_bot
      authorize @bot, policy_class: CommunityBotPolicy
    end

    def bot_params
      params.require(:user).permit(:name, :username, :profile_image)
    end

    protected

    def authorization_resource
      User
    end
  end
end
