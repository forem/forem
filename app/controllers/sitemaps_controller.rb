class SitemapsController < ApplicationController
  before_action :set_cache_control_headers, only: %i[show]

  SITEMAP_REGEX = /\Asitemap-(?<date_string>[A-Z][a-z][a-z]-\d{4})\.xml\z/

  def show
    match = params[:sitemap].match(SITEMAP_REGEX)
    not_found unless match && match[:date_string]
    begin
      date = Time.zone.parse(match[:date_string]).at_beginning_of_month
    rescue ArgumentError
      not_found
    end

    @articles = Article.published
      .where("published_at > ? AND published_at < ? AND score > ?", date, date.end_of_month, 3)
      .pluck(:path, :last_comment_at)

    set_surrogate_controls(date)
    set_cache_control_headers(@max_age,
                              stale_while_revalidate: @stale_while_revalidate,
                              stale_if_error: @stale_if_error)
    render layout: false
  end

  private

  def set_surrogate_controls(date)
    @stale_if_error = "86400"
    if date > 1.month.ago
      @max_age = "8640" # one hour
      @stale_while_revalidate = "43200" # half a day
    else
      @max_age = "259200" # three days
      @stale_while_revalidate = "432000" # five days
    end
  end
end
