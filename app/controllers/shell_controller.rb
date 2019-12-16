class ShellController < ApplicationController
  layout false

  def top
    @shell = true
    render partial: "top"
  end

  def bottom
    @shell = true
    render partial: "bottom"
  end
end
