class ImageUploadsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized
  rescue_from Errno::ENAMETOOLONG, with: :log_image_data_to_datadog

  def create
    authorize :image_upload

    begin
      limit_uploads

      raise CarrierWave::IntegrityError if params[:image].blank?

      unless valid_filename?
        respond_to do |format|
          format.json { render json: { error: FILENAME_TOO_LONG_MESSAGE }, status: :unprocessable_entity }
        end
        return
      end

      uploaders = upload_images(params[:image])
    rescue RateLimitChecker::LimitReached => e
      respond_to do |format|
        format.json do
          response.headers["Retry-After"] = e.retry_after
          render json: { error: e.message }, status: :too_many_requests
        end
      end
      return
    rescue CarrierWave::IntegrityError => e # client error
      respond_to do |format|
        format.json do
          render json: { error: e.message }, status: :unprocessable_entity
        end
      end
      return
    rescue CarrierWave::ProcessingError # server error
      respond_to do |format|
        format.json do
          render json: { error: "A server error has occurred!" }, status: :unprocessable_entity
        end
      end
      return
    end

    cloudinary_link(uploaders)
  end

  def cloudinary_link(uploaders)
    links = if params[:wrap_cloudinary]
              [ApplicationController.helpers.cloud_cover_url(uploaders[0].url)]
            else
              uploaders.map(&:url)
            end
    respond_to do |format|
      format.json { render json: { links: links }, status: :ok }
    end
  end

  private

  def limit_uploads
    rate_limit!(:image_upload)
  end

  def valid_filename?
    images = Array.wrap(params.dig("image"))
    images.none? { |image| long_filename?(image) }
  end

  def upload_images(images)
    Array.wrap(images).map do |image|
      ArticleImageUploader.new.tap do |uploader|
        uploader.store!(image)
        rate_limiter.track_image_uploads
      end
    end
  end
end
