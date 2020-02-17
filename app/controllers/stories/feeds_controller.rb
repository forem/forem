class Stories::FeedsController < ApplicationController
  before_action :set_cache_control_headers

  def show
    @stories = assign_feed_stories
    respond_to do |format|
      format.json do
        render json: @stories.to_json(
          only: %i[
            title path id user_id comments_count positive_reactions_count organization_id
            reading_time video_thumbnail_url video video_duration_in_minutes language
            experience_level_rating experience_level_rating_distribution cached_user
            cached_organization main_image
          ],
          methods: %i[
            readable_publish_date cached_tag_list_array flare_tag class_name
            cloudinary_video_url video_duration_in_minutes published_at_int
            published_timestamp
          ],
        )
      end
    end
  end

  private

  def assign_feed_stories
    feed = Articles::Feed.new(number_of_articles: 35, page: @page, tag: params[:tag])
    stories = if %w[week month year infinity].include?(params[:timeframe])
                feed.top_articles_by_timeframe(timeframe: params[:timeframe])
              elsif params[:timeframe] == "latest"
                feed.latest_feed
              else
                feed.default_home_feed(user_signed_in: user_signed_in?)
              end
    ArticleDecorator.decorate_collection(stories)
  end
end
