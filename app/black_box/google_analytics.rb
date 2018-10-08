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
      make_report_request("ga:pagePath==#{article.path}", "ga:pageviews")
    end
    pageviews = fetch_all_results(requests)
    @article_ids.zip(pageviews).to_h
  end

  def get_feed_impression_info
    requests = @article_ids.map do |id|
      make_report_request("ga:eventAction==featured-feed-impression;ga:eventLabel==articles-#{id}",
        "ga:totalEvents")
    end
    results = fetch_all_results(requests)
    @article_ids.zip(results).to_h
  end

  def get_feed_click_info
    requests = @article_ids.map do |id|
      make_report_request("ga:eventAction==featured-feed-click;ga:eventLabel==articles-#{id}",
        "ga:totalEvents")
    end
    results = fetch_all_results(requests)
    @article_ids.zip(results).to_h
  end

  private

  def fetch_all_results(requests)
    results = []
    i = 0
    while i < requests.length
      done_request = fetch_analytics_for(*requests[i..i + 4])
      results.concat(done_request)
      i += 5
    end
    results
  end

  def make_report_request(filters_expression_string, metrics_string)
    ReportRequest.new(
      view_id: ApplicationConfig["GA_VIEW_ID"],
      filters_expression: filters_expression_string,
      metrics: [Metric.new(expression: metrics_string)],
      date_ranges: [
        DateRange.new(start_date: "2015-01-01", end_date: "today"),
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
