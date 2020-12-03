module Admin
  class PodcastsController < Admin::ApplicationController
    layout "admin"

    before_action :find_podcast, only: %i[edit update fetch remove_owner add_owner]
    before_action :find_user, only: %i[remove_owner add_owner]

    def index
      @podcasts = Podcast.left_outer_joins(:podcast_episodes)
        .select("podcasts.*, count(podcast_episodes) as episodes_count")
        .group("podcasts.id").order("podcasts.created_at" => :desc)
        .page(params[:page]).per(50)

      return if params[:search].blank?

      @podcasts = @podcasts.where("podcasts.title ILIKE :search", search: "%#{params[:search]}%")
    end

    def edit; end

    def update
      if @podcast.update(podcast_params)
        redirect_to admin_podcasts_path, notice: "Podcast updated"
      else
        render :edit
      end
    end

    def fetch
      limit = params[:limit].to_i.zero? ? nil : params[:limit].to_i
      force = params[:force].to_i == 1
      Podcasts::GetEpisodesWorker.perform_async(podcast_id: @podcast.id, limit: limit, force: force)
      flash[:notice] = "Podcast's episodes fetching was scheduled (#{@podcast.title}, ##{@podcast.id})"
      redirect_to admin_podcasts_path
    end

    def remove_owner
      removed_roles = @user.remove_role(:podcast_owner, @podcast)
      if removed_roles.empty?
        redirect_to edit_admin_podcast_path(@podcast), notice: "Error"
      else
        redirect_to admin_podcasts_path, notice: "Removed owner"
      end
    end

    def add_owner
      role = @user.add_role(:podcast_owner, @podcast)
      if role.persisted?
        redirect_to admin_podcasts_path, notice: "Added owner"
      else
        redirect_to edit_admin_podcast_path(@podcast), notice: "Error"
      end
    end

    private

    def find_podcast
      @podcast = Podcast.find(params[:id])
    end

    def find_user
      @user = User.find_by(id: params[:podcast][:user_id])
      redirect_to edit_admin_podcast_path(@podcast), notice: "No such user" unless @user
    end

    def podcast_params
      allowed_params = %i[
        title
        feed_url
        description
        itunes_url
        overcast_url
        android_url
        soundcloud_url
        website_url
        twitter_username
        pattern_image
        main_color_hex
        slug
        image
        reachable
        published
      ]
      params.require(:podcast).permit(allowed_params)
    end
  end
end
