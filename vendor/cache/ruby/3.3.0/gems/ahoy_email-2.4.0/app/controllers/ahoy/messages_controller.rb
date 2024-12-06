module Ahoy
  class MessagesController < ApplicationController
    filters = _process_action_callbacks.map(&:filter) - AhoyEmail.preserve_callbacks
    skip_before_action(*filters, raise: false)
    skip_after_action(*filters, raise: false)
    skip_around_action(*filters, raise: false)

    # legacy
    def open
      send_data Base64.decode64("R0lGODlhAQABAPAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=="), type: "image/gif", disposition: "inline"
    end

    def click
      legacy = params[:id]
      if legacy
        token = params[:id].to_s
        campaign = nil
        url = params[:url].to_s
        signature = params[:signature].to_s
      else
        token = params[:t].to_s
        campaign = params[:c].to_s
        url = params[:u].to_s
        signature = params[:s].to_s
      end

      redirect_options = {}
      redirect_options[:allow_other_host] = true

      if AhoyEmail::Utils.signature_verified?(legacy: legacy, token: token, campaign: campaign, url: url, signature: signature)
        data = {}
        data[:campaign] = campaign if campaign
        data[:token] = token
        data[:url] = url
        data[:controller] = self
        AhoyEmail::Utils.publish(:click, data)

        redirect_to url, **redirect_options
      else
        if AhoyEmail.invalid_redirect_url
          redirect_to AhoyEmail.invalid_redirect_url, **redirect_options
        else
          render plain: "Link expired", status: :not_found
        end
      end
    end
  end
end
