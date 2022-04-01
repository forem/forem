class ImageUploadsController < ApplicationController
  before_action :authenticate_user!
  before_action :limit_uploads, only: [:create]
  after_action :verify_authorized

  def create
    authorize :image_upload

    begin
      raise CarrierWave::IntegrityError if params[:image].blank?

      invalid_image_error_message = validate_image
      unless invalid_image_error_message.nil?
        respond_to do |format|
          format.json { render json: { error: invalid_image_error_message }, status: :unprocessable_entity }
        end
        return
      end

      uploaders = upload_images(params[:image])
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
          render json: { error: I18n.t("image_uploads_controller.server_error") },
                 status: :unprocessable_entity
        end
      end
      return
    end

    links = uploaders.map(&:url)
    respond_to do |format|
      format.json { render json: { links: links }, status: :ok }
    end
  end

  private

  def limit_uploads
    rate_limit!(:image_upload)
  end

  def validate_image
    images = Array.wrap(params["image"])
    return if images.blank?
    return is_not_file_message unless valid_image_files?(images)
    return filename_too_long_message unless valid_filenames?(images)

    nil
  end

  def valid_image_files?(images)
    images.none? { |image| !file?(image) }
  end

  def valid_filenames?(images)
    images.none? { |image| long_filename?(image) }
  end

  def upload_images(images)
    Array.wrap(images).map do |image|
      ArticleImageUploader.new.tap do |uploader|
        uploader.store!(image)
        rate_limiter.track_limit_by_action(:image_upload)
      end
    end
  end
end
