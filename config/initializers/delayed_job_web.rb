DelayedJobWeb.use Rack::Auth::Basic do |username, password|
  username == ApplicationConfig["APP_NAME"] && password == ApplicationConfig["APP_PASSWORD"]
end
