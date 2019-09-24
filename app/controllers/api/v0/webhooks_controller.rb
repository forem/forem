module Api
  module V0
    class WebhooksController < ApiController
      respond_to :json
      before_action :authenticate!
      before_action -> { doorkeeper_authorize! :public }, if: -> { doorkeeper_token }
      skip_before_action :verify_authenticity_token, only: %w[create destroy]

      def index
        @webhooks = webhooks_scope.order(:id)
      end

      def create
        @webhook = @user.webhook_endpoints.new(webhook_params)
        @webhook.oauth_application_id = doorkeeper_token.application_id if doorkeeper_token
        @webhook.save!
        render "show", status: :created
      end

      def show
        @webhook = webhooks_scope.find(params[:id])
      end

      def destroy
        webhook = webhooks_scope.find(params[:id])
        webhook.destroy!
        head :no_content
      end

      private

      def webhooks_scope
        if doorkeeper_token
          @user.webhook_endpoints.for_app(doorkeeper_token.application_id)
        else
          @user.webhook_endpoints
        end
      end

      def webhook_params
        params.require(:webhook_endpoint).permit(:target_url, :source, events: [])
      end
    end
  end
end
