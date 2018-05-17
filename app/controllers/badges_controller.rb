class BadgesController < ApplicationController

  def show
    @badge = Badge.find_by_slug(params[:slug])
  end
end