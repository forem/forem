class Internal::PodcastsController < Internal::ApplicationController
  layout "internal"

  before_action :find_podcast, only: %i[edit update fetch remove_admin add_admin]
  before_action :find_user, only: %i[remove_admin add_admin]

  def index
    @podcasts = Podcast.left_outer_joins(:podcast_episodes).
      select("podcasts.*, count(podcast_episodes) as episodes_count").
      group("podcasts.id").order("podcasts.created_at DESC").
      page(params[:page]).per(50)
    @podcasts = @podcasts.where("podcasts.title ILIKE :search", search: "%#{params[:search]}%") if params[:search].present?
  end

  def edit; end

  def update
    if @podcast.update(podcast_params)
      redirect_to internal_podcasts_path, notice: "Podcast updated"
    else
      render :edit
    end
  end

  def fetch
    limit = params[:limit].to_i.zero? ? nil : params[:limit].to_i
    force = params[:force].to_i == 1
    Podcasts::GetEpisodesWorker.perform_async(podcast_id: @podcast.id, limit: limit, force: force)
    flash[:notice] = "Podcast's episodes fetching was scheduled (#{@podcast.title}, ##{@podcast.id})"
    redirect_to internal_podcasts_path
  end

  def remove_admin
    removed_roles = @user.remove_role(:podcast_admin, @podcast)
    if removed_roles.empty?
      redirect_to edit_internal_podcast_path(@podcast), notice: "Error"
    else
      redirect_to internal_podcasts_path, notice: "Removed admin"
    end
  end

  def add_admin
    role = @user.add_role(:podcast_admin, @podcast)
    if role.persisted?
      redirect_to internal_podcasts_path, notice: "Added admin"
    else
      redirect_to edit_internal_podcast_path(@podcast), notice: "Error"
    end
  end

  private

  def find_podcast
    @podcast = Podcast.find(params[:id])
  end

  def find_user
    @user = User.find_by(id: params[:podcast][:user_id])
    redirect_to edit_internal_podcast_path(@podcast), notice: "No such user" unless @user
  end

  def podcast_params
    allowed_params = %i[
      title feed_url
    ]
    params.require(:podcast).permit(allowed_params)
  end
end
