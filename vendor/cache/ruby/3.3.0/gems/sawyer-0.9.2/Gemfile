source "http://rubygems.org"

gemspec

gem "rake"

group :test do
  gem "minitest"
end

install_if -> { ENV["FARADAY_VERSION"] } do
  gem "faraday", ENV["FARADAY_VERSION"]
end
