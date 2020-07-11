module Internal
  class WebhookEndpointsController < Internal::ApplicationController
    layout "internal"

    def index
      @endpoints = Webhook::Endpoint.includes(:user)
        .page(params[:page]).per(50)
        .order("created_at desc")
    end
  end
end
