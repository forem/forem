module Admin
  class OverviewController < Admin::ApplicationController
    layout "admin"
    def index
      @open_abuse_reports_count =
        FeedbackMessage
          .where(status: "Open", feedback_type: "abuse-reports")
          .count
    end
  end
end
