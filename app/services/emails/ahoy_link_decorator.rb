module Emails
  # Re-applies Ahoy's email link tracking to a Customer.io message_data payload.
  #
  # Ahoy rewrites links in the ActionMailer-rendered HTML body. Customer.io
  # discards that body and renders its own template from message_data, so on the
  # Customer.io path none of the recipient's links carry tracking parameters and
  # Ahoy::EmailClicksController is never reached. Everything that controller
  # drives goes dark with it: clicked_at, email FeedEvents (which feed
  # FeedConfig#feed_success_score), the user interest embedding, billboard click
  # events, last_presence_at, and the user_clicks_email_link field test
  # conversion.
  #
  # The URL rules themselves live in Emails::AhoyLinkTracking, shared with the
  # AhoyEmail::Processor patch that does the same job for the SMTP path.
  class AhoyLinkDecorator
    def self.call(message_data, ahoy_data:)
      new(message_data, ahoy_data).call
    end

    def initialize(message_data, ahoy_data)
      @message_data = message_data
      @token = ahoy_data.is_a?(Hash) ? ahoy_data[:token] : nil
      @campaign = ahoy_data.is_a?(Hash) ? ahoy_data[:campaign] : nil
    end

    # The token is only present when click tracking is on (AHOY_EMAIL_CLICK_ON
    # in production) and AhoyEmail.save_token is set, and the after_action that
    # populates it is wrapped in Safely.safely -- so a missing token is an
    # ordinary state, not an error. Tracking is never worth losing a send over,
    # so anything unexpected falls back to the undecorated payload.
    def call
      return @message_data if @token.blank? || @message_data.blank?

      remove_instance_variable(:@native_context) if defined?(@native_context)

      if (ctx = native_context)
        native = ForemNative.ahoy_decorate_payload(@message_data, *ctx)
        return native unless native.nil?
      end

      decorate(@message_data)
    rescue StandardError => e
      Rails.logger.warn("[ahoy_link_decorator] skipped: #{e.class}: #{e.message}")
      @message_data
    ensure
      remove_instance_variable(:@native_context) if defined?(@native_context)
    end

    private

    def native_context
      return @native_context if defined?(@native_context)

      @native_context = if AhoyLinkTracking.native_signing_available?
                          [
                            Settings::General.app_domain.to_s,
                            @token.to_s,
                            @campaign&.to_s,
                            AhoyEmail.secret_token,
                            AhoyLinkTracking.external_base_url(url_options),
                          ]
                        end
    end

    def decorate(value)
      case value
      when Hash
        value.transform_values { |nested| decorate(nested) }
      when Array
        value.map { |nested| decorate(nested) }
      when String
        decorate_string(value)
      else
        value
      end
    end

    # Payload values are either bare URLs (an article's "url") or fragments of
    # rendered HTML ("smart_summary", billboard processed_html).
    def decorate_string(value)
      return decorate_html(value) if value.include?("<a")

      decorate_url(value) || value
    end

    def decorate_html(html)
      if (ctx = native_context)
        native = ForemNative.ahoy_decorate_html(html, *ctx)
        return native unless native.nil?
      end

      legacy_decorate_html(html)
    end

    def legacy_decorate_html(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      doc.css("a[href]").each do |link|
        next if skip_attribute?(link)

        decorated = decorate_url(link["href"])
        link["href"] = decorated if decorated
      end
      # Matches the body rewriting in config/initializers/ahoy_email.rb, which
      # unescapes ampersands for the same reason.
      doc.to_s.gsub("&amp;", "&")
    end

    def skip_attribute?(link)
      return false unless link["data-skip-click"]

      link.remove_attribute("data-skip-click")
      true
    end

    # Returns nil when the value should keep its original string.
    def decorate_url(href)
      if (ctx = native_context)
        native = ForemNative.ahoy_decorate_url(href, *ctx)
        return if native == false
        return native if native.is_a?(String)
      end

      legacy_decorate_url(href)
    rescue StandardError => e
      # One unparseable link must not cost the whole payload its tracking.
      Rails.logger.warn("[ahoy_link_decorator] link skipped: #{e.class}: #{e.message}")
      nil
    end

    def legacy_decorate_url(href)
      uri = AhoyLinkTracking.parse_uri(href)
      return unless AhoyLinkTracking.trackable?(uri)
      return if AhoyLinkTracking.skip?(uri, href)

      if AhoyLinkTracking.internal?(uri)
        AhoyLinkTracking.internal_url(uri, href, token: @token, campaign: @campaign)
      else
        AhoyLinkTracking.external_url(
          href, token: @token, campaign: @campaign, url_options: url_options
        )
      end
    end

    # ApplicationMailer#setup_subforem_context sets this per message, so it
    # carries the subforem-aware host the ERB layout used. Read at delivery
    # time, same as the token.
    def url_options
      ActionMailer::Base.default_url_options || {}
    end
  end
end
