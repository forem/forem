# frozen_string_literal: true

module Ferrum
  class Headers
    def initialize(page)
      @page = page
      @headers = {}
    end

    #
    # Get all headers.
    #
    # @return [Hash{String => String}]
    #
    def get
      @headers
    end

    #
    # Set given headers. Eventually clear all headers and set given ones.
    #
    # @param [Hash{String => String}] headers
    #   key-value pairs for example `"User-Agent" => "Browser"`.
    #
    # @return [true]
    #
    def set(headers)
      clear
      add(headers)
    end

    #
    # Clear all headers.
    #
    # @return [true]
    #
    def clear
      @headers = {}
      true
    end

    #
    # Adds given headers to already set ones.
    #
    # @param [Hash{String => String}] headers
    #   key-value pairs for example `"Referer" => "http://example.com"`.
    #
    # @param [Boolean] permanent
    #
    # @return [true]
    #
    def add(headers, permanent: true)
      if headers["Referer"]
        @page.referrer = headers["Referer"]
        headers.delete("Referer") unless permanent
      end

      @headers.merge!(headers)
      user_agent = @headers["User-Agent"]
      accept_language = @headers["Accept-Language"]

      set_overrides(user_agent: user_agent, accept_language: accept_language)
      @page.command("Network.setExtraHTTPHeaders", headers: @headers)
      true
    end

    private

    def set_overrides(user_agent: nil, accept_language: nil, platform: nil)
      options = {}
      options[:userAgent] = user_agent || @page.browser.default_user_agent
      options[:acceptLanguage] = accept_language if accept_language
      options[:platform] if platform

      @page.command("Network.setUserAgentOverride", **options) unless options.empty?
    end
  end
end
