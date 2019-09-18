module Api
  module V0
    class WebhooksController < ApiController
      respond_to :json
      before_action :authenticate!

      skip_before_action :verify_authenticity_token, only: %w[create destroy]

      def index
        @webhooks = @user.webhook_endpoints.order(:id)
      end

      def create
        @webhook = @user.webhook_endpoints.create!(webhook_params)
        render "show", status: :created
      end

      def show
        @webhook = @user.webhook_endpoints.find(params[:id])
      end

      def destroy
        webhook = @user.webhook_endpoints.find(params[:id])
        webhook.destroy!
        head :no_content
      end

      private

      def webhook_params
        params.require(:webhook_endpoint).permit(:target_url, :source, events: [])
      end
    end
  end
end
