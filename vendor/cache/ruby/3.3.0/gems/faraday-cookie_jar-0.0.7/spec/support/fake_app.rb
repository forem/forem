require 'sinatra'

class FakeApp < Sinatra::Application
  get '/dump' do
    "foo=#{request.cookies['foo']}"
  end

  get '/default' do
    response.set_cookie "foo", :value => "bar"
  end

  get '/path' do
    response.set_cookie "foo", :value => "bar", :path => "/path"
  end

  get '/expires' do
    response.set_cookie "foo", :value => "bar", :expires => Time.now + 1
  end

  get '/multiple_cookies' do
    "foo=#{request.cookies['foo']};language=#{request.cookies['language']}"
  end
end
