module Ahoy
  class EmailClicksController < ApplicationController
    skip_before_action :verify_authenticity_token # Signitures are used to verify requests here
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
      @token = ahoy_params[:t].to_s
      @campaign = ahoy_params[:c].to_s
      @url = ahoy_params[:u].to_s
      @signature = ahoy_params[:s].to_s
      expected_signature = AhoyEmail::Utils.signature(token: @token, campaign: @campaign, url: @url)

      return if ActiveSupport::SecurityUtils.secure_compare(@signature, expected_signature)

      render plain: "Invalid signature", status: :forbidden
    end

    def ahoy_params
      params.permit(:t, :c, :u, :s)
    end
  end
end
