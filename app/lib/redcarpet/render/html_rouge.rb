module Redcarpet
  module Render
    class HTMLRouge < HTML
      MERMAID_LANGUAGE = "mermaid".freeze
      MERMAID_MAX_SOURCE_BYTES = 20_000
      MERMAID_MAX_LINES = 500

      # Rouge requires the hint language to be lower case, by overriding this
      # method we can allow the hint language to be specified with other casings
      # eg. `Ada` instead of `ada`
      def block_code(code, language)
        normalized_language = language.to_s.downcase
        diagram = mermaid_block(code) if mermaid_language?(normalized_language)

        diagram || ForemNative.syntax_highlight_code_block(code, normalized_language)
      end

      def image(link, title, alt_text)
        url = resolve_media_store_url(link)
        ForemNative.redcarpet_render_image(link, url, title, alt_text) ||
          legacy_image(link, url, title, alt_text)
      end

      def link(link, _title, content)
        if content&.include?("<img")
          return render_linked_image(link, content)
        end

        proto, domain = link_app_origin_if_needed(link)
        native_result = ForemNative.redcarpet_render_link(
          link, content, rendered_link_attributes, proto, domain, raw_href: false
        )
        return if native_result == :nested_link
        return native_result if native_result

        legacy_link(link, content)
      end

      def header(title, header_number)
        ForemNative.redcarpet_render_header(title, header_number) ||
          legacy_header(title, header_number)
      end

      private

      def legacy_image(link, url, title, alt_text)
        return "" unless allowed_uri?(link, allow_data: true)

        safe_url = escape_uri_attribute(url)
        title_attr = title ? %( title="#{escape_attribute(title)}") : ""
        alt_text_attr = alt_text ? %( alt="#{escape_attribute(alt_text)}") : ""
        %(<img src="#{safe_url}"#{title_attr}#{alt_text_attr}/>)
      end

      def render_linked_image(link, content)
        attrs = ForemNative.redcarpet_extract_img_attrs(content)
        if attrs
          image_url, alt_text, title = attrs
        else
          doc = Nokogiri::HTML(content)
          img = doc.at_css("img")
          image_url = img["src"]
          alt_text = img["alt"] || nil
          title = img["title"] || nil
        end

        modified_content = image(image_url, title, alt_text)
        native_wrapped = ForemNative.redcarpet_render_link(
          link, modified_content, "", "", "", raw_href: true
        )
        return native_wrapped if native_wrapped

        return %(<a>#{modified_content}</a>) unless allowed_uri?(link)

        %(<a href="#{escape_uri_attribute(link)}">#{modified_content}</a>)
      end

      def legacy_link(link, content)
        return if %r{<a\s.+/a>}.match?(content)
        return %(<a>#{content}</a>) unless allowed_uri?(link)

        link_attributes = rendered_link_attributes
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

      def legacy_header(title, header_number)
        anchor_link = slugify(title)
        <<~HEREDOC
          <h#{header_number}>
            <a name="#{anchor_link}" href="##{anchor_link}" class="anchor">
            </a>
            #{title}
          </h#{header_number}>
        HEREDOC
      end

      def resolve_media_store_url(link)
        return link unless %r{\Ahttps?://}.match?(link)

        @media_store_cache ||= {}
        return @media_store_cache[link] if @media_store_cache.key?(link)

        @media_store_cache[link] = MediaStore.find_by(original_url: link)&.output_url || link
      end

      def rendered_link_attributes
        return @rendered_link_attributes if defined?(@rendered_link_attributes)

        attrs = @options[:link_attributes]
        @rendered_link_attributes =
          if attrs.blank?
            ""
          else
            attrs.map { |attribute, value| %( #{attribute}="#{escape_attribute(value)}") }.join
          end
      end

      def link_app_origin_if_needed(link)
        if link.is_a?(String) && !link.start_with?("http://", "https://", "#") &&
            link.exclude?(".") && !/\A\w+:/.match?(link)
          [app_protocol.to_s, app_domain.to_s]
        else
          ["", ""]
        end
      end

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
        ForemNative.redcarpet_slugify_header(string) || legacy_slugify(string)
      end

      def legacy_slugify(string)
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
