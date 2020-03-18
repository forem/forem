class SitemapsController < ApplicationController
  def show
    date_string = params[:sitemap].gsub("sitemap-", "").gsub(".xml", "")
    date = Time.zone.parse(date_string).at_beginning_of_month
    end_date = (date + 1.month).at_beginning_of_month
    @change_frequency = change_frequency(date)
    @articles = Article.where("published_at > ? AND published_at < ? AND score > ?", date, end_date, 4).
      pluck(:path, :last_comment_at)
    render layout: false
  end

  def change_frequency(date)
    if date > 1.day.ago
      "hourly"
    elsif date > 1.week.ago
      "daily"
    elsif date > 1.month.ago
      "weekly"
    else
      "monthly"
    end
  end
end
