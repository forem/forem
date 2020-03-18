class ShellController < ApplicationController
  before_action :set_cache_control_headers, only: %i[top bottom]

  layout false

  def top
    @shell = true
    set_surrogate_key_header "shell-top"
    render partial: "top"
  end

  def bottom
    @shell = true
    set_surrogate_key_header "shell-bottom"
    render partial: "bottom"
  end
end
