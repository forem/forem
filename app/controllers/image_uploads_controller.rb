class ImageUploadsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def create
    authorize :image_upload
    uploader = ArticleImageUploader.new
    uploader.store!(params[:image])
    link =  if params[:wrap_cloudinary]
              ApplicationController.helpers.cloud_cover_url(uploader.url)
            else
              uploader.url
            end
    respond_to do |format|
      format.json { render json: { link: link }, status: 200 }
    end
  end
end
