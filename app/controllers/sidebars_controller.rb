class SidebarsController < ApplicationController
  layout false

  def show
    get_latest_campaign_articles
  end

  private

  def get_latest_campaign_articles
    @campaign_articles_count = Campaign.current.count
    @latest_campaign_articles = Campaign.current.plucked_article_attributes
  end
end
