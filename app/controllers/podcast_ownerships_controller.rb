class PodcastOwnershipsController < ApplicationController
  before_action :authenticate_user!

  def new
    @podcast_ownership = PodcastOwnership.new
  end

  def create
    @podcast_ownership = PodcastOwnership.new(podcast_ownership_params)

    if @podcast_ownership.save
      flash[:success] = "Owner created successfully"
      redirect_to pod_path
    else
      flash[:error] = "User is already an owner"
      format.html { render :new }
    end
  end

  def edit
    @podcast_ownership = PodcastOwnership.find(params[:id])
  end

  def update
    @podcast_ownership = PodcastOwnership.find(params[:id])

    if @podcast_ownership.update_attributes(podcast_ownership_params)
      @podcast_ownership.save
      flash[:success] = "Updated successfully"
      redirect_to pod_path
    else
      flash[:error] = "Error updating!"
      format.html { render :edit }
    end
  end

  def destroy
    @podcast_ownership = PodcastOwnership.find(params[:id])
    @podcast_ownership.destroy
    redirect_to pod_path
  end
end
