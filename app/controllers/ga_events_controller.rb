class GaEventsController < ApplicationController
  include ApplicationHelper

  def create
    if Settings::General.ga_analytics_4_id.present? && Settings::General.ga_api_secret.present?
      json = JSON.parse(request.raw_post)
      user_id = user_signed_in? ? current_user.id : nil
      client_id = "#{scrambled_ip[0..12]}_#{json['user_agent']}_#{user_id}"

      tracking_service = Ga::TrackingService.new(Settings::General.ga_analytics_4_id, Settings::General.ga_api_secret, client_id)
      tracking_service.track_event("page_view", event_params(json, user_id))

    end
    render body: nil
  end

  private

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
      user_id: user_id,
      user_language: json["user_language"],
      referrer: json["referrer"] && !json["referrer"].start_with?(app_url) ? json["referrer"] : nil,
      user_agent: json["user_agent"],
      viewport_size: json["viewport_size"],
      screen_resolution: json["screen_resolution"],
      document_title: json["document_title"],
      document_encoding: json["document_encoding"],
      document_path: json["document_path"],
      cache_buster: rand(100_000_000_000).to_s,
      data_source: "web"
    }
  end
end
