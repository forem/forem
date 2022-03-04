class LiquidEmbedsController < ApplicationController
  before_action :set_cache_control_headers, only: %i[show]
  after_action :allow_iframe, only: :show
  layout false

  def show
    set_surrogate_key_header params.to_s

    begin
      @rendered_node = Liquid::Template
        .parse("{% #{params[:embeddable]} #{params[:args]} %}")
        .root
        .nodelist
        .first
        .render({})
    rescue StandardError
      raise ActionController::RoutingError, "Not Found"
    end
  end

  private

  def allow_iframe
    response.headers.except! "X-Frame-Options"
  end
end
