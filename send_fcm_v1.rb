require 'net/http'
require 'json'
require 'googleauth'

def get_access_token
  json_key_path = ENV['GOOGLE_APPLICATION_CREDENTIALS'] || ENV['FIREBASE_SA_PATH'] || File.expand_path('firebase-service-account.json', __dir__)
  scope = 'https://www.googleapis.com/auth/firebase.messaging'

  begin
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(json_key_path),
      scope: scope
    )

    authorizer.fetch_access_token!
    return authorizer.access_token
  rescue => e
    puts "Error getting access token: #{e.message}"
    return nil
  end
end

def send_fcm_notification(token, access_token)
  project_id = ENV['FIREBASE_PROJECT_ID'] || 'forem-5d94b'
  url = URI("https://fcm.googleapis.com/v1/projects/#{project_id}/messages:send")

  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(url)
  request['Authorization'] = "Bearer #{access_token}"
  request['Content-Type'] = 'application/json'

  payload = {
    message: {
      token: token,
      notification: {
        title: 'Test from Rails!',
        body: 'FCM V1 API test notification'
      },
      android: { priority: 'high' }
    }
  }

  request.body = payload.to_json

  response = http.request(request)
  puts "Status: #{response.code}"
  puts "Response: #{response.body}"
end

access_token = get_access_token

if access_token
  fcm_token = ENV['FCM_TOKEN'] || ''
  if fcm_token.nil? || fcm_token.strip.empty?
    puts "\nMissing FCM_TOKEN. Usage: FCM_TOKEN=\"<token>\" ruby send_fcm_v1.rb"
    exit 1
  end

  send_fcm_notification(fcm_token, access_token)
else
  puts "\nCouldn't get access token. Ensure firebase-service-account.json exists locally."
end
require 'net/http'
require 'json'
require 'googleauth'

def get_access_token
  # Use the NEW service account JSON for forem-5d94b
  json_key_path = '/home/organicelectronics/forem/firebase-service-account.json'
  
  scope = 'https://www.googleapis.com/auth/firebase.messaging'
  
  begin
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(json_key_path),
      scope: scope
    )
    
    authorizer.fetch_access_token!
    return authorizer.access_token
  rescue => e
    puts "Error getting access token: #{e.message}"
    return nil
  end
end

def send_fcm_notification(token, access_token)
  project_id = "forem-5d94b"  # NEW project ID
  url = URI("https://fcm.googleapis.com/v1/projects/#{project_id}/messages:send")
  
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  
  request = Net::HTTP::Post.new(url)
  request['Authorization'] = "Bearer #{access_token}"
  request['Content-Type'] = 'application/json'
  
  payload = {
    message: {
      token: token,
      notification: {
        title: "Test from Rails!",
        body: "FCM V1 API test notification"
      },
      android: {
        priority: "high"
      }
    }
  }
  
  request.body = payload.to_json
  
  response = http.request(request)
  puts "Status: #{response.code}"
  puts "Response: #{response.body}"
end

# Get access token
access_token = get_access_token

if access_token
  # Read token from ENV or fall back to a hardcoded string
  fcm_token = ENV['FCM_TOKEN'] || ""
  if fcm_token.nil? || fcm_token.strip.empty?
    puts "\nMissing FCM_TOKEN. Usage: FCM_TOKEN=\"<token>\" ruby send_fcm_v1.rb"
    exit 1
  end

  send_fcm_notification(fcm_token, access_token)
else
  puts "\nCouldn't get access token. Make sure you're authenticated with gcloud."
end
