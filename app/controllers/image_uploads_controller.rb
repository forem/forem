class ImageUploadsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def create
    authorize :image_upload

    uploader = ArticleImageUploader.new
    begin
      raise RateLimitChecker::UploadRateLimitReached if RateLimitChecker.new(current_user).limit_by_situation("image_upload")

      uploader.store!(params[:image])
      RateLimitChecker.new(current_user).track_image_uploads
    rescue RateLimitChecker::UploadRateLimitReached
      respond_to do |format|
        format.json { render json: { error: "Upload limit reached!" } }
      end
      return
    rescue CarrierWave::IntegrityError => e # client error
      respond_to do |format|
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
      return
    rescue CarrierWave::ProcessingError # server error
      respond_to do |format|
        format.json { render json: { error: "A server error has occurred!" }, status: :server_error }
      end
      return
    end

    cloudinary_link(uploader)
  end

  def cloudinary_link(uploader)
    link = if params[:wrap_cloudinary]
             ApplicationController.helpers.cloud_cover_url(uploader.url)
           else
             uploader.url
           end

    respond_to do |format|
      format.json { render json: { link: link }, status: :ok }
    end
  end
end
