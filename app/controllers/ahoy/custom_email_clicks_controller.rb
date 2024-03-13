module Ahoy
  class CustomEmailClicksController < ApplicationController
    before_action :verify_signature

    def create
      data = {
        token: @token,
        campaign: @campaign,
        url: @url,
        controller: self
      }
      AhoyEmail::Utils.publish(:click, data)
      head :ok # Renders a blank response with a 200 OK status
    end

    private

    def verify_signature
      @token = params[:t].to_s
      @campaign = params[:c].to_s
      @url = params[:u].to_s
      @signature = params[:s].to_s
      expected_signature = AhoyEmail::Utils.signature(token: @token, campaign: @campaign, url: @url)

      return if ActiveSupport::SecurityUtils.secure_compare(@signature, expected_signature)

      render plain: "Invalid signature", status: :forbidden
    end
  end
end
