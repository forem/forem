namespace :push do
  desc 'Send a test FCM notification: rake push:send_token FCM_TOKEN=... TITLE=... BODY=... URL=...'
  task :send_token do
    token = ENV['FCM_TOKEN']
    abort 'FCM_TOKEN is required' if token.nil? || token.strip.empty()

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
end
