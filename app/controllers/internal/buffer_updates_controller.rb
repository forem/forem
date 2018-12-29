class Internal::BufferUpdatesController < Internal::ApplicationController
  def create
    article = Article.find(params[:article_id])
    fb_post = params[:fb_post]
    tweet = params[:tweet]
    if params[:social_channel] == "main_twitter"
      Bufferizer.new(article, tweet).main_teet!
      render body: nil
    elsif params[:social_channel] == "satellite_twitter"
      Bufferizer.new(article, tweet).satellite_tweet!
      render body: nil
    elsif params[:social_channel] == "facebook"
      Bufferizer.new(article, fb_post).facebook_post!
      render body: nil
    end
  end
end
