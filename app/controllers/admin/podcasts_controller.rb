module Admin
  class PodcastsController < Admin::ApplicationController
    layout "admin"

    before_action :find_podcast, only: %i[edit update fetch add_owner]

    def index
      @podcasts = Podcast.left_outer_joins(:podcast_episodes)
        .select("podcasts.*, count(podcast_episodes) as episodes_count")
        .group("podcasts.id").order("podcasts.created_at" => :desc)
        .page(params[:page]).per(50)

      return if params[:search].blank?

      @podcasts = @podcasts.where("podcasts.title ILIKE :search", search: "%#{params[:search]}%")
    end

    def edit
      @podcast_ownership = Podcast.find(params[:id])
    end

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

    def add_owner
      @podcast_ownership = @podcast.podcast_ownerships.build(user_id: params["podcast"]["user_id"])
      if @podcast_ownership.save
        redirect_to admin_podcasts_path, notice: "New owner added!"
      else
        redirect_to edit_admin_podcast_path(@podcast), notice: @podcast_ownership.errors_as_sentence
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
