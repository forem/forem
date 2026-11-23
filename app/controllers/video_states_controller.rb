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
      Rails.error.report(e)
    end
    video_code = extract_video_code(request_json)
    @article = video_code ? Article.find_by(video_code: video_code) : nil

    if @article
      @article.update(video_state: "COMPLETED") # Only is called on completion

      NotifyMailer.with(article: @article).video_upload_complete_email.deliver_now

      render json: { message: I18n.t("video_states_controller.video_state_updated") }
    else
      render json: { message: I18n.t("video_states_controller.related_article_not_found") }, status: :not_found
    end
  end

  private

  def extract_video_code(request_json)
    return unless request_json.is_a?(Hash) && request_json[:Message].is_a?(String)

    message_json = JSON.parse(request_json[:Message], symbolize_names: true)
    return unless message_json.is_a?(Hash) && message_json[:input].is_a?(Hash)

    video_code = message_json[:input][:key]
    video_code.is_a?(String) && video_code.present? ? video_code : nil
  rescue JSON::ParserError => e
    Rails.error.report(e)
    nil
  end

  def valid_key
    expected_key = Settings::General.video_encoder_key
    provided_key = params[:key]
    return false if expected_key.blank? || !provided_key.is_a?(String) || provided_key.blank?

    ActiveSupport::SecurityUtils.secure_compare(provided_key, expected_key)
  end
end
