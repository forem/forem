# spec/support/fake_stream.rb
require 'sinatra/base'

class FakeStream < Sinatra::Base
  get '*' do
    json_response 200, 'stream_feed_1.json'
  end

  private

  def json_response(response_code, file_name)
    content_type :json
    status response_code
    File.open(File.dirname(__FILE__) + '/fixtures/' + file_name, 'rb').read
  end
end
