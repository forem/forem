require "rouge/plugins/redcarpet"

module Redcarpet
  module Render
    class HTMLRouge < HTML
      include Rouge::Plugins::Redcarpet

      # Rouge requires the hint language to be lower case, by overriding this
      # method we can allow the hint language to be specified with other casings
      # eg. `Ada` instead of `ada`
      def block_code(code, language)
        super(code, language.to_s.downcase)
      end

      def image(link, title, alt_text)
        # Check if the URL is an image and process accordingly
        if %r{\Ahttps?://}.match?(link)
          modified_url = MediaStore.find_by(original_url: link)&.output_url || link
          title_attr = title ? %( title="#{title}") : ""
          alt_text_attr = alt_text ? %( alt="#{alt_text}") : ""
          %(<img src="#{modified_url}"#{title_attr}#{alt_text_attr}/>)
        else
          title_attr = title ? %( title="#{title}") : ""
          alt_text_attr = alt_text ? %( alt="#{alt_text}") : ""
          %(<img src="#{link}"#{title_attr}#{alt_text_attr}/>)
        end
      end

      def link(link, _title, content) # rubocop:disable Metrics/PerceivedComplexity
        # Regex to capture src, alt, and title attributes from an img tag
        if content&.include?("<img") && (doc = Nokogiri::HTML(content))
          image_url = doc.at_css("img")["src"]
          alt_text = doc.at_css("img")["alt"] || nil
          title = doc.at_css("img")["title"] || nil
          modified_content = image(image_url, title, alt_text) # Call your image method with title and alt text
          %(<a href="#{link}">#{modified_content}</a>)
        else
          # Proceed with normal link rendering if no image is detected
          return if %r{<a\s.+/a>}.match?(content)

          link_attributes = ""
          @options[:link_attributes]&.each do |attribute, value|
            link_attributes += %( #{attribute}="#{value}")
          end
          if (%r{https?://\S+}.match? link) || link.nil?
            %(<a href="#{link}"#{link_attributes}>#{content}</a>)
          elsif /\.{1}/.match? link
            %(<a href="//#{link}"#{link_attributes}>#{content}</a>)
          elsif link.start_with?("#")
            %(<a href="#{link}"#{link_attributes}>#{content}</a>)
          else
            %(<a href="#{app_protocol}#{app_domain}#{link}"#{link_attributes}>#{content}</a>)
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

      def app_protocol
        ApplicationConfig["APP_PROTOCOL"]
      end

      def app_domain
        Settings::General.app_domain
      end

      def slugify(string)
        stripped_string = ActionView::Base.full_sanitizer.sanitize string
        stripped_string.downcase.gsub(EmojiRegex::RGIEmoji, "").strip.gsub(/[[:punct:]]/u, "").gsub(/\s+/, "-")
      end
    end
  end
end
