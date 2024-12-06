require 'spec_helper'

describe Faraday::CookieJar do
  let(:conn) { Faraday.new(:url => 'http://faraday.example.com') }
  let(:cookie_jar) { HTTP::CookieJar.new }

  before do
    conn.use :cookie_jar
    conn.adapter :net_http # for sham_rock
  end

  it 'get default cookie' do
    conn.get('/default')
    expect(conn.get('/dump').body).to eq('foo=bar')
  end

  it 'does not send cookies to wrong path' do
    conn.get('/path')
    expect(conn.get('/dump').body).to_not eq('foo=bar')
  end

  it 'expires cookie' do
    conn.get('/expires')
    expect(conn.get('/dump').body).to eq('foo=bar')
    sleep 2
    expect(conn.get('/dump').body).to_not eq('foo=bar')
  end

  it 'fills an injected cookie jar' do

    conn_with_jar = Faraday.new(:url => 'http://faraday.example.com') do |conn|
      conn.use :cookie_jar, jar: cookie_jar
      conn.adapter :net_http # for sham_rock
    end

    conn_with_jar.get('/default')

    expect(cookie_jar.empty?).to be false

  end

  it 'multiple cookies' do
    conn.get('/default')

    response = conn.send('get') do |request|
      request.url '/multiple_cookies'
      request.headers.merge!({:Cookie => 'language=english'})
    end

    expect(response.body).to eq('foo=bar;language=english')
  end
end

