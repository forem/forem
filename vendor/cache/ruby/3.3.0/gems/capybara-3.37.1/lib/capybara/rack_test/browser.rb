# frozen_string_literal: true

class Capybara::RackTest::Browser
  include ::Rack::Test::Methods

  attr_reader :driver
  attr_accessor :current_host

  def initialize(driver)
    @driver = driver
    @current_fragment = nil
  end

  def app
    driver.app
  end

  def options
    driver.options
  end

  def visit(path, **attributes)
    @new_visit_request = true
    reset_cache!
    reset_host!
    process_and_follow_redirects(:get, path, attributes)
  end

  def refresh
    reset_cache!
    request(last_request.fullpath, last_request.env)
  end

  def submit(method, path, attributes)
    path = request_path if path.nil? || path.empty?
    uri = build_uri(path)
    uri.query = '' if method.to_s.casecmp('get').zero?
    process_and_follow_redirects(method, uri.to_s, attributes, 'HTTP_REFERER' => referer_url)
  end

  def follow(method, path, **attributes)
    return if fragment_or_script?(path)

    process_and_follow_redirects(method, path, attributes, 'HTTP_REFERER' => referer_url)
  end

  def process_and_follow_redirects(method, path, attributes = {}, env = {})
    @current_fragment = build_uri(path).fragment
    process(method, path, attributes, env)
    return unless driver.follow_redirects?

    driver.redirect_limit.times do
      if last_response.redirect?
        if [307, 308].include? last_response.status
          process(last_request.request_method, last_response['Location'], last_request.params, env)
        else
          process(:get, last_response['Location'], {}, env)
        end
      end
    end

    if last_response.redirect? # rubocop:disable Style/GuardClause
      raise Capybara::InfiniteRedirectError, "redirected more than #{driver.redirect_limit} times, check for infinite redirects."
    end
  end

  def process(method, path, attributes = {}, env = {})
    method = method.downcase
    new_uri = build_uri(path)
    @current_scheme, @current_host, @current_port = new_uri.select(:scheme, :host, :port)
    @current_fragment = new_uri.fragment || @current_fragment
    reset_cache!
    @new_visit_request = false
    send(method, new_uri.to_s, attributes, env.merge(options[:headers] || {}))
  end

  def build_uri(path)
    uri = URI.parse(path)
    base_uri = base_relative_uri_for(uri)

    uri.path = base_uri.path + uri.path unless uri.absolute? || uri.path.start_with?('/')

    if base_uri.absolute?
      base_uri.merge(uri)
    else
      uri.scheme ||= @current_scheme
      uri.host ||= @current_host
      uri.port ||= @current_port unless uri.default_port == @current_port
      uri
    end
  end

  def current_url
    uri = build_uri(last_request.url)
    uri.fragment = @current_fragment if @current_fragment
    uri.to_s
  rescue Rack::Test::Error
    ''
  end

  def reset_host!
    uri = URI.parse(driver.session_options.app_host || driver.session_options.default_host)
    @current_scheme, @current_host, @current_port = uri.select(:scheme, :host, :port)
  end

  def reset_cache!
    @dom = nil
  end

  def dom
    @dom ||= Capybara::HTML(html)
  end

  def find(format, selector)
    if format == :css
      dom.css(selector, Capybara::RackTest::CSSHandlers.new)
    else
      dom.xpath(selector)
    end.map { |node| Capybara::RackTest::Node.new(self, node) }
  end

  def html
    last_response.body
  rescue Rack::Test::Error
    ''
  end

  def title
    dom.title
  end

  def last_request
    raise Rack::Test::Error if @new_visit_request

    super
  end

  def last_response
    raise Rack::Test::Error if @new_visit_request

    super
  end

protected

  def base_href
    find(:css, 'head > base').first&.[](:href).to_s
  end

  def base_relative_uri_for(uri)
    base_uri = URI.parse(base_href)
    current_uri = URI.parse(safe_last_request&.url.to_s).tap do |c|
      c.path.sub!(%r{/[^/]*$}, '/') unless uri.path.empty?
      c.path = '/' if c.path.empty?
    end

    if [current_uri, base_uri].any?(&:absolute?)
      current_uri.merge(base_uri)
    else
      base_uri.path = current_uri.path if base_uri.path.empty?
      base_uri
    end
  end

  def build_rack_mock_session
    reset_host! unless current_host
    Rack::MockSession.new(app, current_host)
  end

  def request_path
    last_request.path
  rescue Rack::Test::Error
    '/'
  end

  def safe_last_request
    last_request
  rescue Rack::Test::Error
    nil
  end

private

  def fragment_or_script?(path)
    path.gsub(/^#{Regexp.escape(request_path)}/, '').start_with?('#') || path.downcase.start_with?('javascript:')
  end

  def referer_url
    build_uri(last_request.url).to_s
  rescue Rack::Test::Error
    ''
  end
end
