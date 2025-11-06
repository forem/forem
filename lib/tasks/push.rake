require_relative '../../app/services/push/fcm_v1_client'
require_relative '../../app/services/push/apns_client'

namespace :push do
  desc 'Send a test FCM notification: rake push:send_token FCM_TOKEN=... TITLE=... BODY=... URL=...'
  task :send_token do
    token = ENV['FCM_TOKEN']
    abort 'FCM_TOKEN is required' if token.nil? || token.strip.empty?

    title = ENV['TITLE'] || 'Forem test'
    body  = ENV['BODY']  || 'Hello from Rails via FCM v1'
    data  = {}
    data[:url] = ENV['URL'] if ENV['URL']

  project_id = ENV['FIREBASE_PROJECT_ID'] || 'forem-5d94b'
  sa_path    = ENV['GOOGLE_APPLICATION_CREDENTIALS'] || ENV['FIREBASE_SA_PATH'] || File.expand_path('../../firebase-service-account.json', __dir__)

    client = Push::FcmV1Client.new(project_id: project_id, service_account_path: sa_path)
    res = client.send_to_token(token: token, title: title, body: body, data: data)
    puts "Status: #{res[:status]}\nBody: #{res[:body]}"
    abort 'Push failed' unless res[:status] == 200
  end

  desc 'Unified push send: rake push:send PLATFORM=android|ios TOKEN=... TITLE=... BODY=... [DRY_RUN=true] [URL=...]'
  task :send do
    platform = ENV['PLATFORM']&.downcase
    abort 'PLATFORM must be android or ios' unless %w[android ios].include?(platform)

    token = ENV['TOKEN'] || ENV['FCM_TOKEN'] || ENV['APNS_TOKEN']
    abort 'TOKEN is required' if token.nil? || token.strip.empty?

    title = ENV['TITLE'] || 'Forem test'
    body  = ENV['BODY']  || 'Hello from Rails push:send'
    data  = {}
    data[:url] = ENV['URL'] if ENV['URL']
    dry_run = (ENV['DRY_RUN'] == 'true')

    if platform == 'android'
      project_id = ENV['FIREBASE_PROJECT_ID'] || 'forem-5d94b'
      sa_path    = ENV['GOOGLE_APPLICATION_CREDENTIALS'] || ENV['FIREBASE_SA_PATH'] || File.expand_path('../../firebase-service-account.json', __dir__)
      client = Push::FcmV1Client.new(project_id: project_id, service_account_path: sa_path)
      res = client.send_to_token(token: token, title: title, body: body, data: data)
      puts "Android FCM Status: #{res[:status]}\nBody: #{res[:body]}"
      abort 'Push failed' unless res[:status] == 200
    else
      team_id   = ENV['APNS_TEAM_ID'] || 'TEAMID'
      key_id    = ENV['APNS_KEY_ID']  || 'KEYID'
      bundle_id = ENV['APNS_BUNDLE_ID'] || 'org.example.app'
      p8_path   = ENV['APNS_P8_PATH'] || File.expand_path('../../apns-key.p8', __dir__)
      env       = ENV['APNS_ENV'] || 'development'

      client = Push::ApnsClient.new(team_id: team_id, key_id: key_id, bundle_id: bundle_id, p8_path: p8_path, environment: env)
      res = client.send_token(token: token, title: title, body: body, data: data, dry_run: dry_run)
      if res[:status] == :dry_run
        puts "iOS APNs DRY RUN\nEndpoint: #{res[:endpoint]}\nHeaders: #{res[:headers]}\nPayload: #{res[:payload].to_json}"
      elsif res[:status] == :not_implemented
        puts "iOS APNs send not implemented yet (#{res[:message]})"
      elsif res[:status] == :error
        abort "APNs error: #{res[:error]}"
      else
        puts "APNs response: #{res.inspect}"
      end
    end
  end
end
