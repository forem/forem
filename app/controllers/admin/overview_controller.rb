module Admin
  class OverviewController < Admin::ApplicationController
    layout "admin"
    def index
      @open_abuse_reports_count =
        FeedbackMessage.open_abuse_reports.size
    end
  end
end
