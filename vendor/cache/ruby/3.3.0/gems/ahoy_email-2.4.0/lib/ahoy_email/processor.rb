module AhoyEmail
  class Processor
    attr_reader :mailer, :options

    UTM_PARAMETERS = %w(utm_source utm_medium utm_term utm_content utm_campaign)

    def initialize(mailer, options)
      @mailer = mailer
      @options = options

      unknown_keywords = options.keys - AhoyEmail.default_options.keys
      raise ArgumentError, "unknown keywords: #{unknown_keywords.join(", ")}" if unknown_keywords.any?
    end

    def perform
      track_links if options[:utm_params] || options[:click]
      track_message if options[:message]
      message.ahoy_options = options
    end

    protected

    def message
      mailer.message
    end

    def token
      @token ||= SecureRandom.urlsafe_base64(32).gsub(/[\-_]/, "").first(32)
    end

    def track_message
      data = {
        mailer: options[:mailer],
        extra: options[:extra],
        user: options[:user]
      }

      if options[:click]
        data[:token] = token if AhoyEmail.save_token
        data[:campaign] = campaign
      end

      if options[:utm_params]
        UTM_PARAMETERS.map(&:to_sym).each do |k|
          data[k] = options[k] if options[k]
        end
      end

      mailer.message.ahoy_data = data
    end

    def track_links
      if html_part?
        part = message.html_part || message

        doc = parser_class.parse(part.body.raw_source)
        doc.css("a[href]").each do |link|
          uri = parse_uri(link["href"])
          next unless trackable?(uri)
          # utm params first
          if options[:utm_params] && !skip_attribute?(link, "utm-params")
            params = uri.query_values(Array) || []
            UTM_PARAMETERS.each do |key|
              next if params.any? { |k, _v| k == key } || !options[key.to_sym]
              params << [key, options[key.to_sym]]
            end
            uri.query_values = params
            link["href"] = uri.to_s
          end

          if options[:click] && !skip_attribute?(link, "click")
            signature = Utils.signature(token: token, campaign: campaign, url: link["href"])
            link["href"] =
              url_for(
                controller: "ahoy/messages",
                action: "click",
                t: token,
                c: campaign,
                u: link["href"],
                s: signature
              )
          end
        end

        # ampersands converted to &amp;
        # https://github.com/sparklemotion/nokogiri/issues/1127
        # not ideal, but should be equivalent in html5
        # https://stackoverflow.com/questions/15776556/whats-the-difference-between-and-amp-in-html5
        # escaping technically required before html5
        # https://stackoverflow.com/questions/3705591/do-i-encode-ampersands-in-a-href
        part.body = doc.to_s
      end
    end

    # use document instead of fragment
    # https://github.com/ankane/ahoy_email/pull/150
    def parser_class
      case options[:html5]
      when true
        Nokogiri::HTML5::Document
      when false
        Nokogiri::HTML4::Document
      else
        Nokogiri::HTML::Document
      end
    end

    def html_part?
      (message.html_part || message).content_type =~ /html/
    end

    def skip_attribute?(link, suffix)
      attribute = "data-skip-#{suffix}"
      if link[attribute]
        # remove it
        link.remove_attribute(attribute)
        true
      elsif link["href"].to_s =~ /unsubscribe/i && !options[:unsubscribe_links]
        # try to avoid unsubscribe links
        true
      else
        false
      end
    end

    # Filter trackable URIs, i.e. absolute one with http
    def trackable?(uri)
      uri && uri.absolute? && %w(http https).include?(uri.scheme)
    end

    # Parse href attribute
    # Return uri if valid, nil otherwise
    def parse_uri(href)
      # to_s prevent to return nil from this method
      Addressable::URI.heuristic_parse(href.to_s) rescue nil
    end

    def url_for(opt)
      opt = (mailer.default_url_options || {})
            .merge(options[:url_options])
            .merge(opt)
      AhoyEmail::Engine.routes.url_helpers.url_for(opt)
    end

    # return nil if false
    def campaign
      options[:campaign] || nil
    end
  end
end
