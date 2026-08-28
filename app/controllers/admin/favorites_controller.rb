module Admin
  class FavoritesController < Admin::ApplicationController
    layout "admin"

    def index
      @leaderboard = Favorites::ImpactData.call
    end

    protected

    def authorization_resource
      User
    end
  end
end
