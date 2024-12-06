# frozen_string_literal: true

require 'sinatra/base'
require 'json'

class TestApp < Sinatra::Base
  set :environment, :test
  set :server, 'webrick'
  disable :protection

  set :counter, 0
  set :requests, 0
  set :yesterday, (Date.today - 1).httpdate

  get '/ping' do
    'PONG'
  end

  get '/clear' do
    settings.counter = 0
    settings.requests = 0
    status 204
  end

  get '/json' do
    json = JSON.dump(count: increment_counter.to_i)
    [200, { 'Cache-Control' => 'max-age=400', 'Content-Type' => 'application/json' }, json]
  end

  get '/image' do
    image = File.expand_path('empty.png', __dir__)
    data  = IO.binread(image)
    [200, { 'Cache-Control' => 'max-age=400', 'Content-Type' => 'image/png' }, data]
  end

  post '/post' do
    [200, { 'Cache-Control' => 'max-age=400' }, increment_counter]
  end

  get '/broken' do
    [500, { 'Cache-Control' => 'max-age=400' }, increment_counter]
  end

  get '/counter' do
    [200, { 'Cache-Control' => 'max-age=200' }, increment_counter]
  end

  post '/counter' do
  end

  put '/counter' do
  end

  delete '/counter' do
  end

  patch '/counter' do
  end

  get '/get' do
    [200, { 'Cache-Control' => 'max-age=200' }, increment_counter]
  end

  post '/delete-with-location' do
    [200, { 'Location' => "#{request.base_url}/get" }, '']
  end

  post '/delete-with-content-location' do
    [200, { 'Content-Location' => "#{request.base_url}/get" }, '']
  end

  post '/get' do
    halt 405
  end

  get '/private' do
    [200, { 'Cache-Control' => 'private, max-age=100' }, increment_counter]
  end

  get '/dontstore' do
    [200, { 'Cache-Control' => 'no-store' }, increment_counter]
  end

  get '/expires' do
    [200, { 'Expires' => (Time.now + 10).httpdate }, increment_counter]
  end

  get '/yesterday' do
    [200, { 'Date' => settings.yesterday, 'Expires' => settings.yesterday }, increment_counter]
  end

  get '/must-revalidate' do
    [200, { 'Date' => Time.now.httpdate, 'Cache-Control' => 'public, max-age=23880, must-revalidate, no-transform' }, increment_counter]
  end

  get '/timestamped' do
    settings.counter += 1
    header = settings.counter > 2 ? '1' : '2'

    if env['HTTP_IF_MODIFIED_SINCE'] == header
      [304, {}, '']
    else
      [200, { 'Last-Modified' => header }, increment_counter]
    end
  end

  get '/etag' do
    settings.counter += 1
    tag = settings.counter > 2 ? '1' : '2'

    if env['HTTP_IF_NONE_MATCH'] == tag
      [304, { 'ETag' => tag, 'Cache-Control' => 'max-age=200', 'Date' => Time.now.httpdate, 'Expires' => (Time.now + 200).httpdate, 'Vary' => '*' }, '']
    else
      [200, { 'ETag' => tag, 'Cache-Control' => 'max-age=0', 'Date' => settings.yesterday, 'Expires' => Time.now.httpdate, 'Vary' => 'Accept' }, increment_counter]
    end
  end

  get '/no_cache' do
    [200, { 'Cache-Control' => 'max-age=200, no-cache', 'ETag' => settings.counter.to_s }, increment_counter]
  end

  get '/vary' do
    [200, { 'Cache-Control' => 'max-age=50', 'Vary' => 'User-Agent' }, increment_counter]
  end

  get '/vary-wildcard' do
    [200, { 'Cache-Control' => 'max-age=50', 'Vary' => '*' }, increment_counter]
  end

  # Increments the 'requests' counter to act as a newly processed response.
  def increment_counter
    (settings.requests += 1).to_s
  end
end
