module Admin
  class OverviewController < Admin::ApplicationController
    layout "admin"
    def index
    end

    def stats
      period = (params[:period] || 7).to_i
      period = [7, 30, 90].include?(period) ? period : 7
      
      stats = Admin::StatsData.new(period).call
      
      render json: stats
    end
  end
end