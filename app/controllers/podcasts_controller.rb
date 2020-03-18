class PodcastsController < ApplicationController
  before_action :authenticate_user!

  # skip Bullet on create as it currently triggers an error inside the rolify
  # method "current_user.add_role()" we have no control of
  around_action :skip_bullet, only: %i[create], if: -> { defined?(Bullet) }

  def new
    @podcast = Podcast.new
    @podcasts = Podcast.available.order("title asc")
    @podcast_index = true
  end

  def create
    @podcast = Podcast.new(podcast_params)
    @podcast.creator = current_user

    if @podcast.save
      current_user.add_role(:podcast_admin, @podcast) if added_by_owner?
      flash[:global_notice] = "Podcast suggested"

      redirect_to pod_path
    else
      @podcasts = Podcast.available.order(title: :asc)
      @podcast_index = true

      render :new
    end
  end

  private

  def added_by_owner?
    params[:i_am_owner].to_i == 1
  end

  def podcast_params
    allowed_params = %i[
      android_url image itunes_url main_color_hex overcast_url pattern_image
      slug soundcloud_url twitter_username website_url title feed_url description
    ]
    params.require(:podcast).permit(allowed_params)
  end

  def skip_bullet
    previous_value = Bullet.enable?
    Bullet.enable = false

    yield
  ensure
    Bullet.enable = previous_value
  end
end
