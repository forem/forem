class ShellController < ApplicationController
  layout false

  def top
    @shell = true
    render partial: "top"
  end

  def bottom
    render partial: "bottom"
  end
end
