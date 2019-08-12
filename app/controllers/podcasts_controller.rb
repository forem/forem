class PodcastsController < ApplicationController
  before_action :authenticate_user!

  def new
    @podcast = Podcast.new
    @podcasts = Podcast.available.order("title asc")
    @podcast_index = true
  end

  def create
    @podcast = Podcast.new(podcast_params)
    if @podcast.save
      flash[:notice] = "Podcast suggested"
      redirect_to "/pod"
    else
      @podcasts = Podcast.available.order("title asc")
      @podcast_index = true
      render :new
    end
  end

  private

  def podcast_params
    allowed_params = %i[android_url image itunes_url main_color_hex overcast_url pattern_image slug soundcloud_url twitter_username website_url title feed_url description]
    params.require(:podcast).permit(allowed_params)
  end
end
