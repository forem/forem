# frozen_string_literal: true

require 'sinatra/base'
require 'tilt/erb'
require 'rack'
require 'yaml'

class TestApp < Sinatra::Base
  class TestAppError < Exception; end # rubocop:disable Lint/InheritException

  class TestAppOtherError < Exception # rubocop:disable Lint/InheritException
    def initialize(string1, msg)
      super()
      @something = string1
      @message = msg
    end
  end
  set :root, File.dirname(__FILE__)
  set :static, true
  set :raise_errors, true
  set :show_exceptions, false

  # Also check lib/capybara/spec/views/*.erb for pages not listed here

  get '/' do
    response.set_cookie('capybara', value: 'root cookie', domain: request.host, path: request.path)
    'Hello world! <a href="with_html">Relative</a>'
  end

  get '/foo' do
    'Another World'
  end

  get '/redirect' do
    redirect '/redirect_again'
  end

  get '/redirect_with_fragment' do
    redirect '/landed#with_fragment'
  end

  get '/redirect_again' do
    redirect '/landed'
  end

  post '/redirect_307' do
    redirect '/landed', 307
  end

  post '/redirect_308' do
    redirect '/landed', 308
  end

  get '/referer_base' do
    '<a href="/get_referer">direct link</a>' \
      '<a href="/redirect_to_get_referer">link via redirect</a>' \
      '<form action="/get_referer" method="get"><input type="submit"></form>'
  end

  get '/redirect_to_get_referer' do
    redirect '/get_referer'
  end

  get '/get_referer' do
    request.referer.nil? ? 'No referer' : "Got referer: #{request.referer}"
  end

  get '/host' do
    "Current host is #{request.scheme}://#{request.host}:#{request.port}"
  end

  get '/redirect/:times/times' do
    times = params[:times].to_i
    if times.zero?
      'redirection complete'
    else
      redirect "/redirect/#{times - 1}/times"
    end
  end

  get '/landed' do
    'You landed'
  end

  post '/landed' do
    "You post landed: #{params.dig(:form, 'data')}"
  end

  get '/with-quotes' do
    %q("No," he said, "you can't do that.")
  end

  get '/form/get' do
    %(<pre id="results">#{params[:form].to_yaml}</pre>)
  end

  post '/relative' do
    %(<pre id="results">#{params[:form].to_yaml}</pre>)
  end

  get '/favicon.ico' do
    nil
  end

  post '/redirect' do
    redirect '/redirect_again'
  end

  delete '/delete' do
    'The requested object was deleted'
  end

  get '/delete' do
    'Not deleted'
  end

  get '/redirect_back' do
    redirect back
  end

  get '/redirect_secure' do
    redirect "https://#{request.host}:#{request.port}/host"
  end

  get '/slow_response' do
    sleep 2
    'Finally!'
  end

  get '/set_cookie' do
    cookie_value = 'test_cookie'
    response.set_cookie('capybara', cookie_value)
    "Cookie set to #{cookie_value}"
  end

  get '/get_cookie' do
    request.cookies['capybara']
  end

  get '/get_header' do
    env['HTTP_FOO']
  end

  get '/get_header_via_redirect' do
    redirect '/get_header'
  end

  get '/error' do
    raise TestAppError, 'some error'
  end

  get '/other_error' do
    raise TestAppOtherError.new('something', 'other error')
  end

  get '/load_error' do
    raise LoadError
  end

  get '/with.*html' do
    erb :with_html, locals: { referrer: request.referrer }
  end

  get '/with_title' do
    <<-HTML
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta http-equiv="Content-type" content="text/html; charset=utf-8"/>
          <title>#{params[:title] || 'Test Title'}</title>
        </head>

        <body>
          <svg><title>abcdefg</title></svg>
        </body>
      </html>
    HTML
  end

  get '/base/with_base' do
    <<-HTML
      <!DOCTYPE html>
      <html>
        <head>
          <base href="/">
          <title>Origin</title>
        </head>
        <body>
          <a href="with_title">Title page</a>
          <a href="?a=3">Bare query</a>
        </body>
      </html>
    HTML
  end

  get '/base/with_other_base' do
    <<-HTML
      <!DOCTYPE html>
      <html>
        <head>
          <base href="/base/">
          <title>Origin</title>
        </head>
        <body>
          <a href="with_title">Title page</a>
          <a href="?a=3">Bare query</a>
        </body>
      </html>
    HTML
  end

  get '/csp' do
    response.headers['Content-Security-Policy'] = "default-src 'none'; connect-src 'self'; base-uri 'none'; font-src 'self'; img-src 'self' data:; object-src 'none'; script-src 'self' 'nonce-jAviMuMisoTisVXjgLoWdA=='; style-src 'self' 'nonce-jAviMuMisoTisVXjgLoWdA=='; form-action 'self';"
    <<-HTML
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta http-equiv="Content-type" content="text/html; charset=utf-8"/>
          <title>CSP</title>
        </head>

        <body>
          <div>CSP</div>
        </body>
      </html>
    HTML
  end

  get '/download.csv' do
    content_type 'text/csv'
    'This, is, comma, separated' \
      'Thomas, Walpole, was , here'
  end

  get '/:view' do |view|
    view_template = "#{__dir__}/views/#{view}.erb"
    has_layout = File.exist?(view_template) && File.open(view_template) { |f| f.first.downcase.include?('doctype') }
    erb view.to_sym, locals: { referrer: request.referrer }, layout: !has_layout
  end

  post '/form' do
    self.class.form_post_count += 1
    %(<pre id="results">#{params[:form].merge('post_count' => self.class.form_post_count).to_yaml}</pre>)
  end

  post '/upload_empty' do
    if params[:form][:file].nil?
      'Successfully ignored empty file field.'
    else
      'Something went wrong.'
    end
  end

  post '/upload' do
    buffer = []
    buffer << "Content-type: #{params.dig(:form, :document, :type)}"
    buffer << "File content: #{params.dig(:form, :document, :tempfile).read}"
    buffer.join(' | ')
  rescue StandardError
    'No file uploaded'
  end

  post '/upload_multiple' do
    docs = params.dig(:form, :multiple_documents)
    buffer = [docs.size.to_s]
    docs.each do |doc|
      buffer << "Content-type: #{doc[:type]}"
      buffer << "File content: #{doc[:tempfile].read}"
    end
    buffer.join(' | ')
  rescue StandardError
    'No files uploaded'
  end

  get '/apple-touch-icon-precomposed.png' do
    halt(404)
  end

  class << self
    attr_accessor :form_post_count
  end

  @form_post_count = 0
end

Rack::Handler::Puma.run TestApp, Port: 8070 if $PROGRAM_NAME == __FILE__
