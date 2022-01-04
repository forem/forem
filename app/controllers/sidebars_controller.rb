class SidebarsController < ApplicationController
  layout false
  before_action :set_cache_control_headers, only: %i[show]

  def show
    get_latest_campaign_articles
    set_surrogate_key_header "home-sidebar"
  end

  private

  def get_latest_campaign_articles
    @campaign_articles_count = Campaign.current.count
    @latest_campaign_articles = Campaign.current.plucked_article_attributes
  end
end
