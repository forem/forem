require 'sinatra/base'

class FakeTwitter < Sinatra::Base
  post '/oauth2/token' do
    content_type :json
    status 200
  end

  get '/1.1/statuses/show/:tweet_id' do
    json_response 200, 'tweet_1.json'
  end

  private

  def json_response(response_code, file_name)
    content_type :json
    status response_code
    File.open(File.dirname(__FILE__) + '/fixtures/' + file_name, 'rb').read
  end
end
