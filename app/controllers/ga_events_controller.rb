class GaEventsController < ApplicationMetalController
  include ApplicationHelper
  include ActionController::Head
  include ActionController::Rescue

  rescue_from ActionDispatch::Http::Parameters::ParseError do
    head :bad_request, content_type: "text/plain"
  end

  # No authorization required for entirely public controller

  # This controller is for tracking activity when GA script fails
  # IP is scrambled as to not be persisted to limit fingerprinting abilities on our end.

  def create
    if Settings::General.ga_analytics_4_id.present? && Settings::General.ga_api_secret.present?
      raw_post = request.raw_post
      user_id = session_current_user_id
      base_app_url = app_url
      event_hash = ForemNative.extract_ga_event_params(raw_post, base_app_url, user_id)
      if event_hash == :invalid
        return head :bad_request
      elsif event_hash.nil?
        json = JSON.parse(raw_post)
        return head :bad_request unless json.is_a?(Hash)

        event_hash = event_params(json, user_id).stringify_keys
      end

      client_id = generate_anonymous_client_id
      # The Google Analytics round-trip doesn't affect the (empty) response, so send it from a job.
      Ga::TrackEventWorker.perform_async(client_id, event_hash)
    end
    self.status = 200
    self.content_type = "text/plain"
    self.response_body = ""
  rescue JSON::ParserError
    head :bad_request
  end

  private

  def generate_anonymous_client_id
    client_id = cookies[:client_id] || "#{scrambled_ip[0..12]}.#{SecureRandom.uuid}"
    cookies[:client_id] = { value: client_id, expires: 1.year.from_now }
    client_id
  end

  def scrambled_ip
    crypt = ActiveSupport::MessageEncryptor.new(todays_key)
    crypt.encrypt_and_sign(request.env["HTTP_FASTLY_CLIENT_IP"] || request.env["HTTP_CF_CONNECTING_IP"] || request.remote_ip)
  end

  def todays_key
    Rails.cache.fetch("daily_random_key", expires_in: 48.hours) do
      SecureRandom.random_bytes(32)
    end
  end

  def event_params(json, user_id)
    {
      page_title: json["document_title"],
      page_location: json["document_path"],
      page_path: json["path"],
      user_id: user_id,
      user_language: json["user_language"],
      referrer: json["referrer"] && !json["referrer"].start_with?(app_url) ? json["referrer"] : nil,
      user_agent: json["user_agent"],
      viewport_size: json["viewport_size"],
      screen_resolution: json["screen_resolution"],
      document_encoding: json["document_encoding"],
      data_source: "web"
    }
  end
end
