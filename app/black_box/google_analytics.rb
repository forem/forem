require "google/apis/analyticsreporting_v4"
require "googleauth"
require "ostruct"

class GoogleAnalytics
  include Google::Apis::AnalyticsreportingV4
  include Google::Auth

  def initialize(article_ids = [], user_id = "base")
    @article_ids = article_ids
    @user_id = user_id.to_s
    @client = AnalyticsReportingService.new
    @client.authorization = create_service_account_credential
  end

  def get_pageviews
    requests = @article_ids.map do |id|
      article = Article.find_by_id(id)
      make_report_request("/#{article.username}/#{article.slug}")
    end
    pageviews = []
    i = 0
    while i < requests.length
      done_request = fetch_analytics_for(*requests[i..i + 4])
      pageviews.concat(done_request)
      i += 5
    end
    pageviews = adjust(pageviews)
    @article_ids.zip(pageviews).to_h
  end

  private

  def make_report_request(url)
    ReportRequest.new(
      view_id: ApplicationConfig["GA_VIEW_ID"],
      filters_expression: "ga:pagePath==#{url}",
      metrics: [Metric.new(expression: "ga:pageviews")],
      date_ranges: [
        DateRange.new(start_date: "2012-01-01", end_date: "today"),
      ],
    )
  end

  def fetch_analytics_for(*report_requests)
    grr = GetReportsRequest.new(report_requests: report_requests, quota_user: @user_id.to_s)
    response = @client.batch_get_reports(grr)
    response.reports.map do |report|
      report.data.totals[0].values[0]
    end
  end

  def create_service_account_credential
    ServiceAccountCredentials.make_creds(
      json_key_io: OpenStruct.new(read: ApplicationConfig["GA_SERVICE_ACCOUNT_JSON"]),
      scope: [AUTH_ANALYTICS_READONLY],
    )
  end

  def adjust(pageviews)
    # This is naiively adjusting for "lost views" from adblockers,
    # and ghostery, non-js loaded, etc.
    # We can loosen this in the near future.
    pageviews.map { |n| (n.to_i * 1.1).to_i.to_s }
  end
end
