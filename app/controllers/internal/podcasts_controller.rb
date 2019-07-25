class Internal::PodcastsController < Internal::ApplicationController
  layout "internal"

  def index
    @podcasts = Podcast.order("created_at DESC").page(params[:page]).per(50)
    @podcasts = @podcasts.where("podcasts.title ILIKE :search", search: "%#{params[:search]}%") if params[:search].present?
  end

  def edit
    @podcast = Podcast.find(params[:id])
  end

  def update
    @podcast = Podcast.find(params[:id])
    if @podcast.update(podcast_params)
      redirect_to internal_podcast_path(@podcast), notice: "Всё супер-ок"
    else
      render :edit
    end
  end

  private

  # TODO: implement
  def remove_admin
    # user.remove_role(:podcast_admin, podcast)
  end

  # TODO: implement
  def add_admin
    # user.add_role(:podcast_admin, podcast)
  end

  def podcast_params
    allowed_params = %i[
      title feed_url
    ]
    params.require(:podcast).permit(allowed_params)
  end
end
