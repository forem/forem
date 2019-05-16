class ImageUploadsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def create
    authorize :image_upload

    raise "too many uploads" if RateLimitChecker.new(current_user).limit_by_situation("image_upload")

    uploader = ArticleImageUploader.new
    begin
      uploader.store!(params[:image])
      limit_uploads
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

    link = if params[:wrap_cloudinary]
             ApplicationController.helpers.cloud_cover_url(uploader.url)
           else
             uploader.url
           end

    respond_to do |format|
      format.json { render json: { link: link }, status: 200 }
    end
  end

  def limit_uploads
    count = Rails.cache.read("#{current_user.id}_image_upload")

    if count.nil?
      count = 1
    else
      count += 1
    end

    if count == 10
      Rails.cache.write("#{current_user.id}_image_upload", count, expires_in: 30.seconds)
    else
      Rails.cache.write("#{current_user.id}_image_upload", count)
    end
  end
end
