class HealthController < ApplicationController # :nodoc:
  rescue_from(Exception) { render_down }

  def show
    render_up
  end

  private

  # rubocop:disable Rails/HttpStatus
  def render_up
    render html: html_status(color: "green")
  end

  def render_down
    render html: html_status(color: "red"), status: 500
  end
  # rubocop:enable Rails/HttpStatus

  # rubocop:disable Rails/OutputSafety
  def html_status(color:)
    %(<html><body style="background-color: #{color}"></body></html>).html_safe
  end
  # rubocop:enable Rails/OutputSafety
end
