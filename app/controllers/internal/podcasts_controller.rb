class Internal::PodcastsController < Internal::ApplicationController
  layout "internal"

  before_action :find_podcast, only: %i[edit update remove_admin add_admin]

  def index
    @podcasts = Podcast.order("created_at DESC").page(params[:page]).per(50)
    @podcasts = @podcasts.where("podcasts.title ILIKE :search", search: "%#{params[:search]}%") if params[:search].present?
  end

  def edit; end

  def update
    if @podcast.update(podcast_params)
      redirect_to internal_podcast_path(@podcast), notice: "Всё супер-ок"
    else
      render :edit
    end
  end

  def remove_admin
    user = User.find_by(id: params[:podcast][:user_id])
    unless user
      redirect_to edit_internal_podcast_path(@podcast), notice: "No such user"
      return
    end
    removed_roles = user.remove_role(:podcast_admin, @podcast)
    if removed_roles.empty?
      redirect_to internal_podcast_path(@podcast), notice: "Error"
    else
      redirect_to internal_podcasts_path, notice: "Removed roles"
    end
  end

  def add_admin
    user = User.find_by(id: params[:user_id])
    unless user
      redirect_to edit_internal_podcast_path(@podcast), notice: "No such user"
      return
    end
    role = user.add_role(:podcast_admin, @podcast)
    if role.persisted?
      redirect_to internal_podcasts_path, notice: "Added role"
    else
      redirect_to internal_podcast_path(@podcast), notice: "Error"
    end
  end

  private

  def find_podcast
    @podcast = Podcast.find(params[:id])
  end

  def podcast_params
    allowed_params = %i[
      title feed_url
    ]
    params.require(:podcast).permit(allowed_params)
  end
end
