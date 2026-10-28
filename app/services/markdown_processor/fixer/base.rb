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
      FRONT_MATTER_DETECTOR = /-{3}.*?-{3}/m

      # Match @_username_ that is not preceded by backtick
      USERNAME_WITH_UNDERSCORE_REGEXP = /(?<!`)@_\w+_/

      def self.call(markdown)
        return unless markdown

        legacy_call(markdown)
      end

      def self.legacy_call(markdown)
        fix_methods.reduce(markdown) { |acc, elem| public_send(elem, acc) }
      end
      private_class_method :legacy_call

      def self.fix_methods
        self::METHODS
      end

      def self.add_quotes_to_title(markdown)
        add_quotes_to_section(markdown, section: "title")
      end

      def self.add_quotes_to_description(markdown)
        add_quotes_to_section(markdown, section: "description")
      end

      def self.lowercase_published(markdown)
        ForemNative.fixer_lowercase_published(markdown) || legacy_lowercase_published(markdown)
      end

      def self.convert_new_lines(markdown)
        ForemNative.fixer_convert_new_lines(markdown) || legacy_convert_new_lines(markdown)
      end

      # Handles inputs the native method declines (non-UTF-8 encodings, String subclasses,
      # and invalid byte sequences).
      def self.legacy_convert_new_lines(markdown)
        markdown.gsub("\r\n", "\n")
      end
      private_class_method :legacy_convert_new_lines

      def self.split_tags(markdown)
        ForemNative.fixer_split_tags(markdown) || legacy_split_tags(markdown)
      end

      def self.underscores_in_usernames(markdown)
        ForemNative.fixer_underscores_in_usernames(markdown) || legacy_underscores_in_usernames(markdown)
      end

      # Escapes underscored username that is not in code
      def self.escape_underscored_username_in_line!(line)
        line.scan(USERNAME_WITH_UNDERSCORE_REGEXP).each do |to_escape|
          line.sub!(to_escape, to_escape.gsub("_", "\\_"))
        end
        line
      end

      def self.add_quotes_to_section(markdown, section:)
        ForemNative.fixer_add_quotes_to_section(markdown, section) ||
          legacy_add_quotes_to_section(markdown, section: section)
      end

      # Handles the inputs ForemNative declines (non-UTF-8 encodings, String subclasses,
      # invalid byte sequences, sections that are not plain words).
      def self.legacy_add_quotes_to_section(markdown, section:)
        # Only add quotes to front matter, or text between triple dashes
        markdown.sub(FRONT_MATTER_DETECTOR) do |front_matter|
          front_matter.gsub(/#{section}: ?(?<content>.*?)(\r\n|\n)/m) do |target|
            # `content` is the captured group (.*?)
            captured_text = Regexp.last_match("content")
            # The query below checks if the whole text is wrapped in
            # either single or double quotes.
            match = captured_text.scan(/(^".*"$|^'.*'$)/)
            if match.empty?
              # Double quotes that aren't already escaped will get escaped.
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
      private_class_method :legacy_add_quotes_to_section

      # Handles the inputs ForemNative declines (non-UTF-8 encodings, String subclasses,
      # invalid byte sequences).
      def self.legacy_split_tags(markdown)
        markdown.gsub(/\ntags:.*\n/) do |tags|
          tags.split(" #").join(",").delete("#").gsub(":,", ": ")
        end
      end
      private_class_method :legacy_split_tags

      # Handles the inputs ForemNative declines (non-UTF-8 encodings, String subclasses,
      # invalid byte sequences).
      def self.legacy_lowercase_published(markdown)
        markdown.gsub(/-{3}.*?-{3}/m) do |front_matter|
          front_matter.gsub(/^published: /i, "published: ")
        end
      end
      private_class_method :legacy_lowercase_published

      # Handles the inputs ForemNative declines (non-UTF-8 encodings, String subclasses,
      # invalid byte sequences).
      def self.legacy_underscores_in_usernames(markdown)
        return markdown unless markdown.match?(USERNAME_WITH_UNDERSCORE_REGEXP)

        traverser = MarkdownProcessor::Traverser.new(markdown)
        traverser.each do |line|
          next if traverser.in_codeblock?

          escape_underscored_username_in_line!(line)
        end.join
      end
      private_class_method :legacy_underscores_in_usernames
    end
  end
end
