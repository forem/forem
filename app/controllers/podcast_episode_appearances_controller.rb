class PodcastEpisodeAppearancesController < ApplicationController
  before_action :authenticate_user!, only: %i[new create edit update destroy]
  before_action :set_episode, only: %i[new]
  before_action :set_podcast_episode_appearance, only: %i[show edit update destroy]
  before_action :set_episode_with_strong_params, only: %i[create update]
  before_action :set_podcast_episode_appearances, only: %i[index create update destroy]

  def index; end

  def show; end

  def new
    @podcast_episode_appearance = @episode.podcast_episode_appearances.build
    authorize @podcast_episode_appearance
  end

  def edit
    authorize @podcast_episode_appearance
  end

  def create
    @podcast_episode_appearance = @episode.podcast_episode_appearances.build(podcast_episode_appearance_params)
    authorize @podcast_episode_appearance
    if @podcast_episode_appearance.save
      flash[:success] = "The user has been successfully tagged."
      # get back to podcast episode page
      # redirect_to "/#{@episode.podcast.slug}/#{@episode.slug}"
      appearances = PodcastEpisodeAppearance.where(podcast_episode_id: @episode.id)
      # NOTE: temporary solution until the UI is designed
      render :output, locals: { podcast_episode_appearances: appearances }
    else
      flash[:error] = "The user cannot be tagged - #{errors_as_sentence}"
      bad_arguments!
    end
  rescue Pundit::NotAuthorizedError
    flash[:error] = "The user cannot be tagged; you must be an owner of this podcast to be able to tag users."
    user_not_authorized!
  end

  def update
    authorize @podcast_episode_appearance
    if @podcast_episode_appearance.update(podcast_episode_appearance_params)
      flash[:success] = "The podcast appearance details have been successfully updated."
      # get back to podcast episode page
      # redirect_to "/#{@episode.podcast.slug}/#{@episode.slug}"
      appearances = PodcastEpisodeAppearance.where(podcast_episode_id: @episode.id)
      render :output, locals: { podcast_episode_appearances: appearances }
    else
      flash[:error] = "Details cannot be updated - #{errors_as_sentence}"
      render :edit
    end
  rescue Pundit::NotAuthorizedError
    flash[:error] = "The podcast appearance details cannot be updated; you must be an owner of this
              podcast to be able to update these details."
    user_not_authorized!
  end

  def destroy
    authorize @podcast_episode_appearance
    episode_id = @podcast_episode_appearance.podcast_episode.id
    if @podcast_episode_appearance.destroy
      flash[:notice] = "Podcast episode appearance was successfully removed."
    else
      flash[:error] = "Action failed. Podcast episode appearance could not be removed - #{errors_as_sentence}"
    end
    appearances = PodcastEpisodeAppearance.where(podcast_episode_id: episode_id)
    render :output, locals: { podcast_episode_appearances: appearances }
  rescue Pundit::NotAuthorizedError
    flash[:error] = "The podcast episode appearance details cannot be deleted; you must be an owner of this
              podcast to be able to delete podcast appearance."
    user_not_authorized!
  end

  private

  def set_podcast_episode_appearances
    # TODO: change to PodcastEpisodeAppearance.where(podcast_episode_id: @episode.id)
    @podcast_episode_appearances = PodcastEpisodeAppearance.all
  end

  def set_episode
    @episode = PodcastEpisode.available.find(params[:episode_id])
  end

  def set_episode_with_strong_params
    @episode = PodcastEpisode.available.find(podcast_episode_appearance_params[:podcast_episode_id])
  end

  def set_podcast_episode_appearance
    @podcast_episode_appearance = PodcastEpisodeAppearance.find(params[:id])
  end

  def set_podcast_episode_appearances_by_episode
    set_podcast_episode_appearance
    episode_id = @podcast_episode_appearance.podcast_episode.id
    @podcast_episode_appearances = PodcastEpisodeAppearance.find_by(podcast_episode_id: episode_id)
  end

  def podcast_episode_appearance_params
    params.require(:podcast_episode_appearance).permit(:podcast_episode_id, :user_id, :role)
  end

  def user_not_authorized!
    render :index, status: :unauthorized
  end

  def bad_arguments!
    render :index, status: :unprocessable_entity
  end

  def errors_as_sentence
    @podcast_episode_appearance.errors.full_messages.to_sentence
  end
end
