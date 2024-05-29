class GaEventsController < ApplicationController
  include ApplicationHelper

  # No authorization required for entirely public controller

  # This controller is for tracking activity when GA script fails
  # IP is scrambled as to not be persisted to limit fingerprinting abilities on our end.

  def create
    if Settings::General.ga_analytics_4_id.present? && Settings::General.ga_api_secret.present?
      json = JSON.parse(request.raw_post)
      user_id = user_signed_in? ? current_user.id : nil
      client_id = generate_anonymous_client_id
      tracking_service = Ga::TrackingService.new(Settings::General.ga_analytics_4_id,
                                                 Settings::General.ga_api_secret,
                                                 client_id)
      tracking_service.track_event("page_view", event_params(json, user_id))
    end
    render body: nil
  end

  private

  def generate_anonymous_client_id
    client_id = cookies[:client_id] || "#{scrambled_ip[0..12]}.#{SecureRandom.uuid}"
    cookies[:client_id] = { value: client_id, expires: 1.year.from_now }
    client_id
  end

  def scrambled_ip
    crypt = ActiveSupport::MessageEncryptor.new(todays_key)
    crypt.encrypt_and_sign(request.env["HTTP_FASTLY_CLIENT_IP"] || request.remote_ip)
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
