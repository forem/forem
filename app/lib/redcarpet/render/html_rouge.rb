require "rouge/plugins/redcarpet"

module Redcarpet
  module Render
    class HTMLRouge < HTML
      include Rouge::Plugins::Redcarpet

      MERMAID_LANGUAGE = "mermaid".freeze
      MERMAID_MAX_SOURCE_BYTES = 20_000
      MERMAID_MAX_LINES = 500

      # Rouge requires the hint language to be lower case, by overriding this
      # method we can allow the hint language to be specified with other casings
      # eg. `Ada` instead of `ada`
      def block_code(code, language)
        normalized_language = language.to_s.downcase
        diagram = mermaid_block(code) if mermaid_language?(normalized_language)

        diagram || super(code, normalized_language)
      end

      def image(link, title, alt_text)
        return "" unless allowed_uri?(link, allow_data: true)

        # Check if the URL is an image and process accordingly
        url = if %r{\Ahttps?://}.match?(link)
                MediaStore.find_by(original_url: link)&.output_url || link
              else
                link
              end
        safe_url = escape_uri_attribute(url)
        title_attr = title ? %( title="#{escape_attribute(title)}") : ""
        alt_text_attr = alt_text ? %( alt="#{escape_attribute(alt_text)}") : ""
        %(<img src="#{safe_url}"#{title_attr}#{alt_text_attr}/>)
      end

      def link(link, _title, content) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        # Regex to capture src, alt, and title attributes from an img tag
        if content&.include?("<img") && (doc = Nokogiri::HTML(content))
          image_url = doc.at_css("img")["src"]
          alt_text = doc.at_css("img")["alt"] || nil
          title = doc.at_css("img")["title"] || nil
          modified_content = image(image_url, title, alt_text) # Call your image method with title and alt text
          return %(<a>#{modified_content}</a>) unless allowed_uri?(link)

          %(<a href="#{escape_uri_attribute(link)}">#{modified_content}</a>)
        else
          # Proceed with normal link rendering if no image is detected
          return if %r{<a\s.+/a>}.match?(content)
          return %(<a>#{content}</a>) unless allowed_uri?(link)

          link_attributes = ""
          @options[:link_attributes]&.each do |attribute, value|
            link_attributes += %( #{attribute}="#{escape_attribute(value)}")
          end
          safe_link = escape_uri_attribute(link)
          if (%r{\Ahttps?://\S+}.match? link) || link.nil?
            %(<a href="#{safe_link}"#{link_attributes}>#{content}</a>)
          elsif /\A\w+:/.match?(link)
            # Handle links with protocols (mailto:, tel:, ftp:, etc.)
            %(<a href="#{safe_link}"#{link_attributes}>#{content}</a>)
          elsif /\.{1}/.match? link
            %(<a href="//#{safe_link}"#{link_attributes}>#{content}</a>)
          elsif link.start_with?("#")
            %(<a href="#{safe_link}"#{link_attributes}>#{content}</a>)
          else
            %(<a href="#{app_protocol}#{app_domain}#{safe_link}"#{link_attributes}>#{content}</a>)
          end
        end
      end

      def header(title, header_number)
        anchor_link = slugify(title)
        <<~HEREDOC
          <h#{header_number}>
            <a name="#{anchor_link}" href="##{anchor_link}" class="anchor">
            </a>
            #{title}
          </h#{header_number}>
        HEREDOC
      end

      private

      def mermaid_language?(language)
        language.split.first == MERMAID_LANGUAGE
      end

      # Returns nil so `block_code` falls back to the syntax highlighted code block.
      def mermaid_block(code)
        source = code.to_s.strip
        return if source.empty?
        return if source.bytesize > MERMAID_MAX_SOURCE_BYTES
        return if source.count("\n") >= MERMAID_MAX_LINES

        %(<pre data-lang="#{MERMAID_LANGUAGE}"><code>#{ERB::Util.html_escape(source)}</code></pre>\n)
      rescue StandardError => e
        Rails.logger.error("Mermaid block rendering failed: #{e.class}: #{e.message}")
        nil
      end

      def app_protocol
        ApplicationConfig["APP_PROTOCOL"]
      end

      def app_domain
        Settings::General.app_domain
      end

      def slugify(string)
        stripped_string = ForemNative.full_sanitize(string) || ActionView::Base.full_sanitizer.sanitize(string)
        downcased = stripped_string.downcase
        without_emoji = ForemNative.strip_rgi_emoji(downcased) || downcased
        without_emoji.strip.gsub(/[[:punct:]]/u, "").gsub(/\s+/, "-")
      end

      def allowed_uri?(uri, allow_data: false)
        return true if uri.nil?

        unescaped = fully_unescape_html(uri.to_s).strip
        return false if !allow_data && unescaped.gsub(/[\x00-\x20]+/, "").match?(/\Adata:/i)

        Loofah::HTML5::Scrub.allowed_uri?(unescaped)
      end

      def fully_unescape_html(str)
        prev = nil
        while str != prev
          prev = str
          str = CGI.unescape_html(str)
        end
        str
      end

      def escape_attribute(value)
        ERB::Util.html_escape(CGI.unescapeHTML(value.to_s))
      end

      def escape_uri_attribute(uri)
        uri.to_s.gsub('"', "&quot;").gsub("<", "&lt;").gsub(">", "&gt;")
      end
    end
  end
end
