DelayedJobWeb.use Rack::Auth::Basic do |username, password|
  username == ENV["APP_NAME"] && password == ENV["APP_PASSWORD"]
end
