# frozen_string_literal: true

require 'net/http'
require 'json'
require 'googleauth'

module Push
  # Minimal Firebase Cloud Messaging v1 client
  class FcmV1Client
    SCOPE = 'https://www.googleapis.com/auth/firebase.messaging'

    def initialize(project_id:, service_account_path:)
      @project_id = project_id
      @service_account_path = service_account_path
    end

    def send_to_token(token:, title:, body:, data: {})
      access_token = fetch_access_token
      raise 'Could not obtain access token' unless access_token

      url = URI("https://fcm.googleapis.com/v1/projects/#{@project_id}/messages:send")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      message = {
        token: token,
        notification: { title: title, body: body },
        data: data.transform_keys(&:to_s),
        android: { priority: 'high' }
      }

      req = Net::HTTP::Post.new(url)
      req['Authorization'] = "Bearer #{access_token}"
      req['Content-Type'] = 'application/json'
      req.body = { message: message }.to_json

      res = http.request(req)
      { status: res.code.to_i, body: res.body }
    end

    private

    def fetch_access_token
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(@service_account_path),
        scope: SCOPE
      )
      authorizer.fetch_access_token!
      authorizer.access_token
    rescue => e
      Rails.logger.error("FCM auth error: #{e.message}") if defined?(Rails)
      nil
    end
  end
end
