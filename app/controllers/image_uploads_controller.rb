class ImageUploadsController < ApplicationController
  before_action :authenticate_user!

  def create
    uploader = ArticleImageUploader.new
    uploader.store!(params[:image])
    link = uploader.url
    respond_to do |format|
      format.json { render json: { link: link }, status: 200 }
    end
  end
end
