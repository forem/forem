module Admin
  class OverviewController < Admin::ApplicationController
    layout "admin"
    def index
      @length = (params[:period] || 7).to_i
      @length = [7, 14, 30, 90].include?(@length) ? @length : 7
      @labels = (@length.downto(1)).map { |n| n.days.ago.strftime("%b %d") }.reverse
      @analytics = Admin::ChartsData.new(@length).call
      @data_counts = Admin::DataCounts.call
    end
  end
end