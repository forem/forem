module Api
  module V0
    class WebhooksController < ApiController
      before_action :authenticate!

      skip_before_action :verify_authenticity_token, only: %w[create destroy]

      ATTRIBUTES_FOR_SERIALIZATION = %i[id user_id source target_url events created_at].freeze
      private_constant :ATTRIBUTES_FOR_SERIALIZATION

      def index
        @webhooks = webhooks_scope.order(:id)
      end

      def create
        @webhook = @user.webhook_endpoints.new(webhook_params)
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
        @user.webhook_endpoints.select(ATTRIBUTES_FOR_SERIALIZATION)
      end

      def webhook_params
        params.require(:webhook_endpoint).permit(:target_url, :source, events: [])
      end
    end
  end
end
