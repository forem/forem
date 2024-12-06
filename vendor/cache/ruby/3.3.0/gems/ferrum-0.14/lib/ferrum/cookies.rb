# frozen_string_literal: true

require "ferrum/cookies/cookie"

module Ferrum
  class Cookies
    include Enumerable

    def initialize(page)
      @page = page
    end

    #
    # Enumerates over all cookies.
    #
    # @yield [cookie]
    #   The given block will be passed each cookie.
    #
    # @yieldparam [Cookie] cookie
    #   A cookie in the browser.
    #
    # @return [Enumerator]
    #   If no block is given, an Enumerator object will be returned.
    #
    def each
      return enum_for(__method__) unless block_given?

      cookies = @page.command("Network.getAllCookies")["cookies"]

      cookies.each do |c|
        yield Cookie.new(c)
      end
    end

    #
    # Returns cookies hash.
    #
    # @return [Hash{String => Cookie}]
    #
    # @example
    #   browser.cookies.all # => {
    #   #  "NID" => #<Ferrum::Cookies::Cookie:0x0000558624b37a40 @attributes={
    #   #     "name"=>"NID", "value"=>"...", "domain"=>".google.com", "path"=>"/",
    #   #     "expires"=>1583211046.575681, "size"=>178, "httpOnly"=>true, "secure"=>false, "session"=>false
    #   #  }>
    #   # }
    #
    def all
      each.to_h do |cookie|
        [cookie.name, cookie]
      end
    end

    #
    # Returns cookie.
    #
    # @param [String] name
    #   The cookie name to fetch.
    #
    # @return [Cookie, nil]
    #   The cookie with the matching name.
    #
    # @example
    #   browser.cookies["NID"] # =>
    #   # <Ferrum::Cookies::Cookie:0x0000558624b67a88 @attributes={
    #   #  "name"=>"NID", "value"=>"...", "domain"=>".google.com",
    #   #  "path"=>"/", "expires"=>1583211046.575681, "size"=>178,
    #   #  "httpOnly"=>true, "secure"=>false, "session"=>false
    #   # }>
    #
    def [](name)
      find { |cookie| cookie.name == name }
    end

    #
    # Sets a cookie.
    #
    # @param [Hash{Symbol => Object}, Cookie] options
    #
    # @option options [String] :name
    #   The cookie param name.
    #
    # @option options [String] :value
    #   The cookie param value.
    #
    # @option options [String] :domain
    #   The domain the cookie belongs to.
    #
    # @option options [String] :path
    #   The path that the cookie is bound to.
    #
    # @option options [Integer] :expires
    #   When the cookie will expire.
    #
    # @option options [Integer] :size
    #   The size of the cookie.
    #
    # @option options [Boolean] :httponly
    #   Specifies whether the cookie `HttpOnly`.
    #
    # @option options [Boolean] :secure
    #   Specifies whether the cookie is marked as `Secure`.
    #
    # @option options [String] :samesite
    #   Specifies whether the cookie is `SameSite`.
    #
    # @option options [Boolean] :session
    #   Specifies whether the cookie is a session cookie.
    #
    # @example
    #   browser.cookies.set(name: "stealth", value: "omg", domain: "google.com") # => true
    #
    # @example
    #   nid_cookie = browser.cookies["NID"] # => <Ferrum::Cookies::Cookie:0x0000558624b67a88>
    #   browser.cookies.set(nid_cookie) # => true
    #
    def set(options)
      cookie = (
        options.is_a?(Cookie) ? options.attributes : options
      ).dup.transform_keys(&:to_sym)

      cookie[:domain] ||= default_domain

      cookie[:httpOnly] = cookie.delete(:httponly) if cookie.key?(:httponly)
      cookie[:sameSite] = cookie.delete(:samesite) if cookie.key?(:samesite)

      expires = cookie.delete(:expires).to_i
      cookie[:expires] = expires if expires.positive?

      @page.command("Network.setCookie", **cookie)["success"]
    end

    #
    # Removes given cookie.
    #
    # @param [String] name
    #
    # @param [Hash{Symbol => Object}] options
    #   Additional keyword arguments.
    #
    # @option options [String] :domain
    #
    # @option options [String] :url
    #
    # @example
    #   browser.cookies.remove(name: "stealth", domain: "google.com") # => true
    #
    def remove(name:, **options)
      raise "Specify :domain or :url option" if !options[:domain] && !options[:url] && !default_domain

      options = options.merge(name: name)
      options[:domain] ||= default_domain

      @page.command("Network.deleteCookies", **options)

      true
    end

    #
    # Removes all cookies for current page.
    #
    # @return [true]
    #
    # @example
    #   browser.cookies.clear # => true
    #
    def clear
      @page.command("Network.clearBrowserCookies")
      true
    end

    private

    def default_domain
      URI.parse(@page.browser.base_url).host if @page.browser.base_url
    end
  end
end
