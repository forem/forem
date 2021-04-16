class ShellController < ApplicationController
  # TODO: Remove these "ShellController", because they are for service worker functionality we no longer need.
  # We are keeping these around mid-March 2021 because previously-installed service workers may still expect them.
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
