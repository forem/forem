# frozen_string_literal: true

require 'ipaddr'
require 'net/http'
require 'resolv'
require 'uri'

class SsrfFilter
  def self.prefixlen_from_ipaddr(ipaddr)
    mask_addr = ipaddr.instance_variable_get('@mask_addr')
    raise ArgumentError, 'Invalid mask' if mask_addr.zero?

    while (mask_addr & 0x1).zero?
      mask_addr >>= 1
    end

    length = 0
    while mask_addr & 0x1 == 0x1
      length += 1
      mask_addr >>= 1
    end

    length
  end
  private_class_method :prefixlen_from_ipaddr

  # https://en.wikipedia.org/wiki/Reserved_IP_addresses
  IPV4_BLACKLIST = [
    ::IPAddr.new('0.0.0.0/8'), # Current network (only valid as source address)
    ::IPAddr.new('10.0.0.0/8'), # Private network
    ::IPAddr.new('100.64.0.0/10'), # Shared Address Space
    ::IPAddr.new('127.0.0.0/8'), # Loopback
    ::IPAddr.new('169.254.0.0/16'), # Link-local
    ::IPAddr.new('172.16.0.0/12'), # Private network
    ::IPAddr.new('192.0.0.0/24'), # IETF Protocol Assignments
    ::IPAddr.new('192.0.2.0/24'), # TEST-NET-1, documentation and examples
    ::IPAddr.new('192.88.99.0/24'), # IPv6 to IPv4 relay (includes 2002::/16)
    ::IPAddr.new('192.168.0.0/16'), # Private network
    ::IPAddr.new('198.18.0.0/15'), # Network benchmark tests
    ::IPAddr.new('198.51.100.0/24'), # TEST-NET-2, documentation and examples
    ::IPAddr.new('203.0.113.0/24'), # TEST-NET-3, documentation and examples
    ::IPAddr.new('224.0.0.0/4'), # IP multicast (former Class D network)
    ::IPAddr.new('240.0.0.0/4'), # Reserved (former Class E network)
    ::IPAddr.new('255.255.255.255') # Broadcast
  ].freeze

  IPV6_BLACKLIST = ([
    ::IPAddr.new('::1/128'), # Loopback
    ::IPAddr.new('64:ff9b::/96'), # IPv4/IPv6 translation (RFC 6052)
    ::IPAddr.new('100::/64'), # Discard prefix (RFC 6666)
    ::IPAddr.new('2001::/32'), # Teredo tunneling
    ::IPAddr.new('2001:10::/28'), # Deprecated (previously ORCHID)
    ::IPAddr.new('2001:20::/28'), # ORCHIDv2
    ::IPAddr.new('2001:db8::/32'), # Addresses used in documentation and example source code
    ::IPAddr.new('2002::/16'), # 6to4
    ::IPAddr.new('fc00::/7'), # Unique local address
    ::IPAddr.new('fe80::/10'), # Link-local address
    ::IPAddr.new('ff00::/8') # Multicast
  ] + IPV4_BLACKLIST.flat_map do |ipaddr|
    prefixlen = prefixlen_from_ipaddr(ipaddr)

    # Don't call ipaddr.ipv4_compat because it prints out a deprecation warning on ruby 2.5+
    ipv4_compatible = IPAddr.new(ipaddr.to_i, Socket::AF_INET6).mask(96 + prefixlen)
    ipv4_mapped = ipaddr.ipv4_mapped.mask(80 + prefixlen)

    [ipv4_compatible, ipv4_mapped]
  end).freeze

  DEFAULT_SCHEME_WHITELIST = %w[http https].freeze

  DEFAULT_RESOLVER = proc do |hostname|
    ::Resolv.getaddresses(hostname).map { |ip| ::IPAddr.new(ip) }
  end

  DEFAULT_ALLOW_UNFOLLOWED_REDIRECTS = false
  DEFAULT_MAX_REDIRECTS = 10

  VERB_MAP = {
    get: ::Net::HTTP::Get,
    put: ::Net::HTTP::Put,
    post: ::Net::HTTP::Post,
    delete: ::Net::HTTP::Delete,
    head: ::Net::HTTP::Head,
    patch: ::Net::HTTP::Patch
  }.freeze

  FIBER_HOSTNAME_KEY = :__ssrf_filter_hostname

  class Error < ::StandardError
  end

  class InvalidUriScheme < Error
  end

  class PrivateIPAddress < Error
  end

  class UnresolvedHostname < Error
  end

  class TooManyRedirects < Error
  end

  class CRLFInjection < Error
  end

  %i[get put post delete head patch].each do |method|
    define_singleton_method(method) do |url, options = {}, &block|
      ::SsrfFilter::Patch::SSLSocket.apply!

      original_url = url
      scheme_whitelist = options.fetch(:scheme_whitelist, DEFAULT_SCHEME_WHITELIST)
      resolver = options.fetch(:resolver, DEFAULT_RESOLVER)
      allow_unfollowed_redirects = options.fetch(:allow_unfollowed_redirects, DEFAULT_ALLOW_UNFOLLOWED_REDIRECTS)
      max_redirects = options.fetch(:max_redirects, DEFAULT_MAX_REDIRECTS)
      url = url.to_s

      response = nil
      (max_redirects + 1).times do
        uri = URI(url)

        unless scheme_whitelist.include?(uri.scheme)
          raise InvalidUriScheme, "URI scheme '#{uri.scheme}' not in whitelist: #{scheme_whitelist}"
        end

        hostname = uri.hostname
        ip_addresses = resolver.call(hostname)
        raise UnresolvedHostname, "Could not resolve hostname '#{hostname}'" if ip_addresses.empty?

        public_addresses = ip_addresses.reject(&method(:unsafe_ip_address?))
        raise PrivateIPAddress, "Hostname '#{hostname}' has no public ip addresses" if public_addresses.empty?

        response, url = fetch_once(uri, public_addresses.sample.to_s, method, options, &block)
        return response if url.nil?
      end

      return response if allow_unfollowed_redirects

      raise TooManyRedirects, "Got #{max_redirects} redirects fetching #{original_url}"
    end
  end

  def self.unsafe_ip_address?(ip_address)
    return true if ipaddr_has_mask?(ip_address)

    return IPV4_BLACKLIST.any? { |range| range.include?(ip_address) } if ip_address.ipv4?
    return IPV6_BLACKLIST.any? { |range| range.include?(ip_address) } if ip_address.ipv6?

    true
  end
  private_class_method :unsafe_ip_address?

  def self.ipaddr_has_mask?(ipaddr)
    range = ipaddr.to_range
    range.first != range.last
  end
  private_class_method :ipaddr_has_mask?

  def self.host_header(hostname, uri)
    # Attach port for non-default as per RFC2616
    if (uri.port == 80 && uri.scheme == 'http') ||
       (uri.port == 443 && uri.scheme == 'https')
      hostname
    else
      "#{hostname}:#{uri.port}"
    end
  end
  private_class_method :host_header

  def self.fetch_once(uri, ip, verb, options, &block)
    if options[:params]
      params = uri.query ? ::URI.decode_www_form(uri.query).to_h : {}
      params.merge!(options[:params])
      uri.query = ::URI.encode_www_form(params)
    end

    hostname = uri.hostname
    uri.hostname = ip

    request = VERB_MAP[verb].new(uri)
    request['host'] = host_header(hostname, uri)

    Array(options[:headers]).each do |header, value|
      request[header] = value
    end

    request.body = options[:body] if options[:body]

    options[:request_proc].call(request) if options[:request_proc].respond_to?(:call)
    validate_request(request)

    http_options = options[:http_options] || {}
    http_options[:use_ssl] = (uri.scheme == 'https')

    with_forced_hostname(hostname) do
      ::Net::HTTP.start(uri.hostname, uri.port, **http_options) do |http|
        response = http.request(request) do |res|
          block&.call(res)
        end
        case response
        when ::Net::HTTPRedirection
          url = response['location']
          # Handle relative redirects
          url = "#{uri.scheme}://#{hostname}:#{uri.port}#{url}" if url.start_with?('/')
        else
          url = nil
        end
        return response, url
      end
    end
  end
  private_class_method :fetch_once

  def self.validate_request(request)
    # RFC822 allows multiline "folded" headers:
    # https://tools.ietf.org/html/rfc822#section-3.1
    # In practice if any user input is ever supplied as a header key/value, they'll get
    # arbitrary header injection and possibly connect to a different host, so we block it
    request.each do |header, value|
      if header.count("\r\n") != 0 || value.count("\r\n") != 0
        raise CRLFInjection, "CRLF injection in header #{header} with value #{value}"
      end
    end
  end
  private_class_method :validate_request

  def self.with_forced_hostname(hostname, &_block)
    ::Thread.current[FIBER_HOSTNAME_KEY] = hostname
    yield
  ensure
    ::Thread.current[FIBER_HOSTNAME_KEY] = nil
  end
  private_class_method :with_forced_hostname
end
