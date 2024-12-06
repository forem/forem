module Ahoy
  class BaseController < ApplicationController
    filters = _process_action_callbacks.map(&:filter) - Ahoy.preserve_callbacks
    skip_before_action(*filters, raise: false)
    skip_after_action(*filters, raise: false)
    skip_around_action(*filters, raise: false)

    if respond_to?(:protect_from_forgery)
      protect_from_forgery with: :null_session, if: -> { Ahoy.protect_from_forgery }
    end

    before_action :verify_request_size
    before_action :check_params
    before_action :renew_cookies

    protected

    def ahoy
      @ahoy ||= Ahoy::Tracker.new(controller: self, api: true)
    end

    def check_params
      if ahoy.send(:missing_params?)
        logger.info "[ahoy] Missing required parameters"
        render plain: "Missing required parameters\n", status: :bad_request
      end
    end

    # set proper ttl if cookie generated from JavaScript
    # approach is not perfect, as user must reload the page
    # for new cookie settings to take effect
    def renew_cookies
      set_ahoy_cookies if params[:js] && !Ahoy.api_only
    end

    def verify_request_size
      if request.content_length > Ahoy.max_content_length
        logger.info "[ahoy] Payload too large"
        render plain: "Payload too large\n", status: :payload_too_large
      end
    end
  end
end
