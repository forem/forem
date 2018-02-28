class ImageUploadsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def create
    csrf_logger_info("image upload")
    uploader = ArticleImageUploader.new
    uploader.store!(params[:image])
    link = uploader.url
    respond_to do |format|
      format.json { render json: { link: link }, status: 200 }
    end
  end
end
