module Api
  module V1
    class BadgeAchievementsController < ApiController
      include Api::BadgeAchievementsController

      before_action :authenticate!
      before_action :require_admin
    end
  end
end