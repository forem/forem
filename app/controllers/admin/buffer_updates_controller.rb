module Admin
  class BufferUpdatesController < Admin::ApplicationController
    def create
      article_id = params[:article_id]
      article = Article.find(article_id) if article_id.present?
      fb_post = params[:fb_post]
      tweet = params[:tweet]
      listing_id = params[:listing_id]
      listing = Listing.find(params[:listing_id]) if listing_id.present?
      article&.update(featured: true)
      case params[:social_channel]
      when "main_twitter"
        Bufferizer::MainTweet.call(article, tweet, current_user.id)
        render body: nil
      when "satellite_twitter"
        Bufferizer::SatelliteTweet.call(article, tweet, current_user.id)
        render body: nil
      when "facebook"
        Bufferizer::FacebookPost.call(article, fb_post, current_user.id)
        render body: nil
      when "listings_twitter"
        Bufferizer::ListingsTweet.call(listing, tweet, current_user.id)
        render body: nil
      end
    end

    def update
      BufferUpdate.upbuff!(params[:id], current_user.id, params[:body_text], params[:status])
      render body: nil
    end

    private

    def authorize_admin
      authorize BufferUpdate, :access?, policy_class: InternalPolicy
    end
  end
end
