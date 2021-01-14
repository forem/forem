module MarkdownProcessor
  module Fixer
    # Services here in the Fixer module should inherit from this base class.
    # #call is implemented here so other services only need to define a
    # METHODS constant that is an Array of symbols referencing other methods
    # found here.
    #
    # For example
    # METHODS = %i[add_quotes_to_tile add_quotes_to_description]
    class Base
      FRONT_MATTER_DETECTOR = /-{3}.*?-{3}/m.freeze

      def self.call(markdown)
        return unless markdown

        fix_methods.reduce(markdown) { |acc, elem| public_send(elem, acc) }
      end

      def self.fix_methods
        self::METHODS
      end

      def self.add_quotes_to_title(markdown)
        add_quotes_to_section(markdown, section: "title")
      end

      def self.add_quotes_to_description(markdown)
        add_quotes_to_section(markdown, section: "description")
      end

      # This turns --- into ------- after the first two,
      # because --- messes with front matter
      def self.modify_hr_tags(markdown)
        markdown.gsub(/^---/).with_index { |match, i| i > 1 ? "#{match}-----" : match }
      end

      def self.lowercase_published(markdown)
        markdown.gsub(/-{3}.*?-{3}/m) do |front_matter|
          front_matter.gsub(/^published: /i, "published: ")
        end
      end

      def self.convert_new_lines(markdown)
        markdown.gsub("\r\n", "\n")
      end

      def self.split_tags(markdown)
        markdown.gsub(/\ntags:.*\n/) do |tags|
          tags.split(" #").join(",").delete("#").gsub(":,", ": ")
        end
      end

      def self.underscores_in_usernames(markdown)
        return markdown unless markdown.match?(USERNAME_WITH_UNDERSCORE_REGEXP)

        traverser = MarkdownTraverser.new(markdown)
        traverser.each do |line|
          next if traverser.in_codeblock?

          escape_underscored_username_in_line!(line)
        end.join
      end

      # Match @_username_ that is not preceded by backtick
      USERNAME_WITH_UNDERSCORE_REGEXP = /(?<!`)@_\w+_/.freeze

      # Escapes underscored username that is not in code
      def self.escape_underscored_username_in_line!(line)
        line.scan(USERNAME_WITH_UNDERSCORE_REGEXP).each do |to_escape|
          line.sub!(to_escape, to_escape.gsub("_", "\\_"))
        end
        line
      end

      def self.add_quotes_to_section(markdown, section:)
        # Only add quotes to front matter, or text between triple dashes
        markdown.sub(FRONT_MATTER_DETECTOR) do |front_matter|
          front_matter.gsub(/#{section}: ?(?<content>.*?)(\r\n|\n)/m) do |target|
            # `content` is the captured group (.*?)
            captured_text = Regexp.last_match("content")
            # The query below checks if the whole text is wrapped in
            # either single or double quotes.
            match = captured_text.scan(/(^".*"$|^'.*'$)/)
            if match.empty?
              # Double quotes that aren't already escaped will get esacped.
              # Then the whole text get warped in double quotes.
              parsed_text = captured_text.gsub(/(?<!\\)"/, "\\\"")
              "#{section}: \"#{parsed_text}\"\n"
            else
              # if the text comes pre-warped in either single or double quotes,
              # no more processing is done
              target
            end
          end
        end
      end
    end
  end
end
