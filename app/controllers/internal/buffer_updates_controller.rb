class Internal::BufferUpdatesController < Internal::ApplicationController
  def create
    article_id = params[:article_id]
    article = Article.find(article_id) if article_id.present?
    fb_post = params[:fb_post]
    tweet = params[:tweet]
    listing = ClassifiedListing.find(params[:listing_id])
    if params[:social_channel] == "main_twitter"
      Bufferizer.new(article, tweet).main_teet!
      render body: nil
    elsif params[:social_channel] == "satellite_twitter"
      Bufferizer.new(article, tweet).satellite_tweet!
      render body: nil
    elsif params[:social_channel] == "facebook"
      Bufferizer.new(article, fb_post).facebook_post!
      render body: nil
    elsif params[:social_channel] == "listings_twitter"
      Bufferizer.new("listing", listing, tweet).listings_tweet!
      render body: nil
    end
  end

  def update
    BufferUpdate.upbuff!(params[:id], current_user.id, params[:body_text], params[:status])
    render body: nil
  end
end
