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
        Bufferizer.new("article", article, tweet, current_user.id).main_tweet!
        render body: nil
      when "satellite_twitter"
        Bufferizer.new("article", article, tweet, current_user.id).satellite_tweet!
        render body: nil
      when "facebook"
        Bufferizer.new("article", article, fb_post, current_user.id).facebook_post!
        render body: nil
      when "listings_twitter"
        Bufferizer.new("listing", listing, tweet, current_user.id).listings_tweet!
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
