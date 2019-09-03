class LiquidEmbedsController < ApplicationController
  before_action :set_cache_control_headers, only: %i[show]
  after_action :allow_iframe, only: :show
  layout false

  def show
    set_surrogate_key_header params.to_s
  end

  private

  def allow_iframe
    response.headers.except! "X-Frame-Options"
  end
end
