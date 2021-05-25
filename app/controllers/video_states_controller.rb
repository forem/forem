class VideoStatesController < ApplicationController
  skip_before_action :verify_authenticity_token
  # Not authorized using pundit because user this is not accessed via user session
  # This is purely for responding to AWS video state changes.

  def create
    unless valid_key
      render json: { message: "invalid_key" }, status: :unprocessable_entity
      return
    end
    begin
      request_json = JSON.parse(request.raw_post, symbolize_names: true)
    rescue StandardError => e
      Honeybadger.notify(e)
    end
    message_json = JSON.parse(request_json[:Message], symbolize_names: true)
    @article = Article.find_by(video_code: message_json[:input][:key])

    if @article
      @article.update(video_state: "COMPLETED") # Only is called on completion

      NotifyMailer.with(article: @article).video_upload_complete_email.deliver_now

      render json: { message: "Video state updated" }
    else
      render json: { message: "Related article not found" }, status: :not_found
    end
  end

  private

  def valid_key
    params[:key] == Settings::General.video_encoder_key
  end
end
