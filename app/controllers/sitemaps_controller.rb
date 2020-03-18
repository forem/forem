class SitemapsController < ApplicationController
  before_action :set_cache_control_headers, only: %i[show]

  def show
    date_string = params[:sitemap].gsub("sitemap-", "").gsub(".xml", "")
    not_found unless date_string.match?(/\A[A-Z][a-z][a-z]\-\d{4}\z/)
    begin
      date = Time.zone.parse(date_string).at_beginning_of_month
    rescue ArgumentError
      not_found
    end
    end_date = (date + 1.month).at_beginning_of_month
    @articles = Article.published.where("published_at > ? AND published_at < ? AND score > ?", date, end_date, 3).pluck(:path, :last_comment_at)

    response.headers["Surrogate-Control"] = if date > 1.month.ago
                                              "max-age=8640, stale-while-revalidate=43200, stale-if-error=86400"
                                            else
                                              "max-age=259200, stale-while-revalidate=432000, stale-if-error=86400"
                                            end
    render layout: false
  end
end
