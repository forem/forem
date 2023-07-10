module Admin
  class BulkAssignRolesController < Admin::ApplicationController
    layout "admin"

    def index
      @all_badges = Badge.all.select(:title, :slug)
    end

    def award
      @all_badges = Badge.all.select(:title, :slug)
    end
  end
end
