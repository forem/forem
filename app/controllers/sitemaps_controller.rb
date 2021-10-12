class SitemapsController < ApplicationController
  before_action :set_cache_control_headers, only: %i[show]

  SITEMAP_REGEX = /\Asitemap-(?<date_string>[A-Z][a-z][a-z]-\d{4})\.xml\z/
  RESULTS_LIMIT = Rails.env.production? ? 10_000 : 5

  def show
    if params[:sitemap].start_with? "sitemap-index"
      sitemap_index
    elsif valid_resource_sitemap?
      resource_sitemap(resource_string)
    else
      monthly_sitemap
    end
    set_cache_control_headers(@max_age,
                              stale_while_revalidate: @stale_while_revalidate,
                              stale_if_error: @stale_if_error)
    render @view_template, layout: false
  end

  private

  def sitemap_index
    set_surrogate_controls(Time.current)
    @articles_count = Article.published
      .where("score >= ?", Settings::UserExperience.index_minimum_score).size
    @page_limit = RESULTS_LIMIT
    @view_template = "index"
  end

  def resource_sitemap(resource)
    case resource
    when "users"
      @users = User.order("comments_count DESC")
        .where("score > -1") # Spam mitigation
        .limit(RESULTS_LIMIT).offset(offset).pluck(:username, :profile_updated_at)
    when "posts"
      @articles = Article.published.order("published_at DESC")
        .where("score >= ?", Settings::UserExperience.index_minimum_score)
        .limit(RESULTS_LIMIT).offset(offset).pluck(:path, :last_comment_at)
    when "tags" # tags
      @tags = Tag.order("hotness_score DESC")
        .where(supported: true)
        .limit(RESULTS_LIMIT).offset(offset).pluck(:name, :updated_at)
    end
    set_surrogate_controls(Time.current)
    @view_template = resource
  end

  def monthly_sitemap
    match = params[:sitemap].match(SITEMAP_REGEX)
    not_found unless match && match[:date_string]
    begin
      date = Time.zone.parse(match[:date_string]).at_beginning_of_month
    rescue ArgumentError
      not_found
    end

    @articles = Article.published
      .where("published_at > ? AND published_at < ? AND score >= ?",
             date, date.end_of_month, Settings::UserExperience.index_minimum_score)
      .pluck(:path, :last_comment_at)

    set_surrogate_controls(date)
    @view_template = "posts"
  end

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

  def valid_resource_sitemap?
    %w[posts users tags].include?(resource_string)
  end

  def resource_string
    params[:sitemap].gsub(".xml", "").split("-")[1]
  end

  def offset
    params[:sitemap].split("-")[2].to_i * RESULTS_LIMIT # elvaluates to 0 if not present or not a number
  end
end
