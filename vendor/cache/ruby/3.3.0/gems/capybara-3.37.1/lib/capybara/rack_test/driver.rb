# frozen_string_literal: true

require 'rack/test'
require 'rack/utils'
require 'mini_mime'
require 'nokogiri'
require 'cgi'

class Capybara::RackTest::Driver < Capybara::Driver::Base
  DEFAULT_OPTIONS = {
    respect_data_method: false,
    follow_redirects: true,
    redirect_limit: 5
  }.freeze
  attr_reader :app, :options

  def initialize(app, **options)
    raise ArgumentError, 'rack-test requires a rack application, but none was given' unless app

    super()
    @app = app
    @options = DEFAULT_OPTIONS.merge(options)
  end

  def browser
    @browser ||= Capybara::RackTest::Browser.new(self)
  end

  def follow_redirects?
    @options[:follow_redirects]
  end

  def redirect_limit
    @options[:redirect_limit]
  end

  def response
    browser.last_response
  end

  def request
    browser.last_request
  end

  def visit(path, **attributes)
    browser.visit(path, **attributes)
  end

  def refresh
    browser.refresh
  end

  def submit(method, path, attributes)
    browser.submit(method, path, attributes)
  end

  def follow(method, path, **attributes)
    browser.follow(method, path, attributes)
  end

  def current_url
    browser.current_url
  end

  def response_headers
    response.headers
  end

  def status_code
    response.status
  end

  def find_xpath(selector)
    browser.find(:xpath, selector)
  end

  def find_css(selector)
    browser.find(:css, selector)
  rescue Nokogiri::CSS::SyntaxError
    raise unless selector.include?(' i]')

    raise ArgumentError, "This driver doesn't support case insensitive attribute matching when using CSS base selectors"
  end

  def html
    browser.html
  end

  def dom
    browser.dom
  end

  def title
    browser.title
  end

  def reset!
    @browser = nil
  end

  def get(...); browser.get(...); end
  def post(...); browser.post(...); end
  def put(...); browser.put(...); end
  def delete(...); browser.delete(...); end
  def header(key, value); browser.header(key, value); end

  def invalid_element_errors
    [Capybara::RackTest::Errors::StaleElementReferenceError]
  end
end
