class GaEventsController < ApplicationController
  include ApplicationHelper
  # No authorization required for entirely public controller

  # This controller is for tracking activity when GA script fails
  # IP is scrambled as to not be persisted to limit fingerprinting abilities on our end.

  def create
    if Settings::General.ga_tracking_id.present?
      json = JSON.parse(request.raw_post)
      user_id = user_signed_in? ? current_user.id : nil
      client_id = "#{scrambled_ip[0..12]}_#{json['user_agent']}_#{user_id}"
      tracker = Staccato.tracker(Settings::General.ga_tracking_id, client_id)
      tracker.pageview(
        path: json["path"],
        user_id: user_id,
        user_language: json["user_language"],
        referrer: (json["referrer"] if json["referrer"] && !json["referrer"].start_with?(app_url)),
        user_agent: json["user_agent"],
        viewport_size: json["viewport_size"],
        screen_resolution: json["screen_resolution"],
        document_title: json["document_title"],
        document_encoding: json["document_encoding"],
        document_path: json["document_path"],
        cache_buster: rand(100_000_000_000).to_s,
        data_source: "web",
      )
    end
    render body: nil
  end

  def scrambled_ip
    crypt = ActiveSupport::MessageEncryptor.new(todays_key)
    crypt.encrypt_and_sign(request.env["HTTP_X_FORWARDED_FOR"] || request.remote_ip)
  end

  def todays_key
    Rails.cache.fetch("daily_random_key", expires_in: 48.hours) do
      SecureRandom.random_bytes(32)
    end
  end
end
