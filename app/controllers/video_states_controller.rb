class VideoStatesController < ApplicationController
  skip_before_action :verify_authenticity_token
  # Not authorized using pundit because user this is not accessed via user session
  # This is purely for responding to AWS video state changes.

  def create
    unless valid_user
      render json: { message: "invalid_user" }, status: :unprocessable_entity
      return
    end
    begin
      logger.info "VIDEO STATES: #{params}"
      request_json = JSON.parse(request.raw_post, symbolize_names: true)
      logger.info "VIDEO STATES: #{request_json}"
    rescue StandardError => e
      Rails.logger.warn(e)
    end
    request_json = JSON.parse(request.raw_post, symbolize_names: true)
    message_json = JSON.parse(request_json[:Message], symbolize_names: true)
    @article = Article.find_by(video_code: message_json[:input][:key])

    if @article
      @article.update(video_state: "COMPLETED") # Only is called on completion
      NotifyMailer.video_upload_complete_email(@article).deliver
      render json: { message: "Video state updated" }
    else
      render json: { message: "Related article not found" }, status: :not_found
    end
  end

  def valid_user
    user = User.find_by(secret: params[:key])
    user = nil unless user.has_role?(:super_admin)
    user
  end
end
