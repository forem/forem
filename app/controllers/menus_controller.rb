class MenusController < ApplicationController
  before_action :authenticate_user!
  def show
  
    @navigation_links = Rails.cache.fetch("navigation_links-#{user_signed_in?}-#{RequestStore.store[:subforem_id]}", expires_in: 15.minutes) do
      {
        default_nav_ids: NavigationLink.from_subforem.default_section.ordered.ids,
        other_nav_ids: NavigationLink.from_subforem.other_section.ordered.ids,
      }
    end
  end
end