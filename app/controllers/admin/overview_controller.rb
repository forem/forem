module Admin
  class OverviewController < Admin::ApplicationController
    layout "admin"

    STATS_CACHE_EXPIRY = 5.minutes
    VALID_STATS_PERIODS = [7, 30, 90].freeze

    def index; end

    def stats
      period = (params[:period] || 7).to_i
      period = 7 unless VALID_STATS_PERIODS.include?(period)

      stats = Rails.cache.fetch("admin/overview/stats/#{period}", expires_in: STATS_CACHE_EXPIRY) do
        Admin::StatsData.new(period).call
      end

      render json: stats
    end
  end
end
