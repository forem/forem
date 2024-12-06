require "cgi"
require "device_detector"
require "uri"

module Ahoy
  class VisitProperties
    attr_reader :request, :params, :referrer, :landing_page

    def initialize(request, api:)
      @request = request
      @params = request.params
      @referrer = api ? params["referrer"] : request.referer
      @landing_page = api ? params["landing_page"] : request.original_url
    end

    def generate
      @generate ||= request_properties.merge(tech_properties).merge(traffic_properties).merge(utm_properties)
    end

    private

    def utm_properties
      landing_params = {}
      begin
        landing_uri = URI.parse(landing_page)
        # could also use Rack::Utils.parse_nested_query
        landing_params = CGI.parse(landing_uri.query) if landing_uri
      rescue
        # do nothing
      end

      props = {}
      %w(utm_source utm_medium utm_term utm_content utm_campaign).each do |name|
        props[name.to_sym] = params[name] || landing_params[name].try(:first)
      end
      props
    end

    def traffic_properties
      uri = URI.parse(referrer) rescue nil
      {
        referring_domain: uri.try(:host).try(:first, 255)
      }
    end

    def tech_properties
      if Ahoy.user_agent_parser == :device_detector
        client = DeviceDetector.new(request.user_agent)
        device_type =
          case client.device_type
          when "smartphone"
            "Mobile"
          when "tv"
            "TV"
          else
            client.device_type.try(:titleize)
          end

        {
          browser: client.name,
          os: client.os_name,
          device_type: device_type
        }
      else
        raise "Add browser to your Gemfile to use legacy user agent parsing" unless defined?(Browser)
        raise "Add user_agent_parser to your Gemfile to use legacy user agent parsing" unless defined?(UserAgentParser)

        # cache for performance
        @@user_agent_parser ||= UserAgentParser::Parser.new

        user_agent = request.user_agent
        agent = @@user_agent_parser.parse(user_agent)
        browser = Browser.new(user_agent)
        device_type =
          if browser.bot?
            "Bot"
          elsif browser.device.tv?
            "TV"
          elsif browser.device.console?
            "Console"
          elsif browser.device.tablet?
            "Tablet"
          elsif browser.device.mobile?
            "Mobile"
          else
            "Desktop"
          end

        {
          browser: agent.name,
          os: agent.os.name,
          device_type: device_type
        }
      end
    end

    # masking based on Google Analytics anonymization
    # https://support.google.com/analytics/answer/2763052
    def ip
      ip = request.remote_ip
      if ip && Ahoy.mask_ips
        Ahoy.mask_ip(ip)
      else
        ip
      end
    end

    def request_properties
      {
        ip: ip,
        user_agent: Ahoy::Utils.ensure_utf8(request.user_agent),
        referrer: referrer,
        landing_page: landing_page,
        platform: params["platform"],
        app_version: params["app_version"],
        os_version: params["os_version"],
        screen_height: params["screen_height"],
        screen_width: params["screen_width"]
      }
    end
  end
end
