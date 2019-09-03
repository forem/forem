module Api
  module V0
    class WebhooksController < ApiController
      respond_to :json
      before_action :authenticate!

      def create
        @webhook = current_user.webhook_endpoints.create!(webhook_params)
        render "show", status: :created
      end

      def show
        @webhook = Webhook::Endpoint.includes(:user).find(params[:id])
      end

      def destroy
        webhook = current_user.webhook_endpoints.find(params[:id])
        webhook.destroy
        render json: { success: webhook.destroyed? }
      end

      private

      def webhook_params
        params.require(:webhook_endpoint).permit(:target_url, :source, events: [])
      end
    end
  end
end
