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
    unless valid_images?
      render :new
      return
    end

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

  def valid_images?
    image_keys = %w[image pattern_image]
    images = podcast_params.select { |k, _v| image_keys.include?(k) }
    return true if images.blank?

    # Create the podcast object to add errors to for the view
    @podcast = Podcast.new(podcast_params.except(*image_keys))
    @podcast.creator = current_user
    return true if valid_image_files_and_names?(images)

    @podcasts = Podcast.available.order(title: :asc)
    @podcast_index = true
    false
  end

  def valid_image_files_and_names?(images)
    images.each do |field, image|
      @podcast.errors.add(field, IS_NOT_FILE_MESSAGE) unless file?(image)
      break if @podcast.errors.any?

      @podcast.errors.add(field, FILENAME_TOO_LONG_MESSAGE) if long_filename?(image)
    end

    @podcast.errors.blank?
  end
end
