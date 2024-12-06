# frozen_string_literal: true

require "action_view"

require "better_html_ext"
require "better_html/better_erb/erubi_implementation"
require "better_html/better_erb/validated_output_buffer"

module BetterHtml
  class BetterErb
    cattr_accessor :content_types

    self.content_types = {
      "html.erb" => BetterHtml::BetterErb::ErubiImplementation,
    }

    class << self
      def prepend!
        ActionView::Template::Handlers::ERB.prepend(ConditionalImplementation)
      end
    end

    module ConditionalImplementation
      def call(template, source = nil)
        generate(template, source)
      end

      private

      def generate(template, source)
        # First, convert to BINARY, so in case the encoding is
        # wrong, we can still find an encoding tag
        # (<%# encoding %>) inside the String using a regular
        # expression

        source ||= template.source
        filename = template.identifier.split("/").last
        exts = filename.split(".")
        exts = exts[1..exts.length].join(".")
        template_source = source.dup.force_encoding(Encoding::ASCII_8BIT)

        erb = template_source.gsub(ActionView::Template::Handlers::ERB::ENCODING_TAG, "")
        encoding = Regexp.last_match(2)

        erb.force_encoding(valid_encoding(source.dup, encoding))

        # Always make sure we return a String in the default_internal
        erb.encode!

        excluded_template = !!BetterHtml.config.template_exclusion_filter&.call(template.identifier)
        klass = BetterHtml::BetterErb.content_types[exts] unless excluded_template
        klass ||= self.class.erb_implementation

        escape = self.class.escape_ignore_list.include?(template.type)
        generator = klass.new(
          erb,
          escape: escape,
          trim: (self.class.erb_trim_mode == "-")
        )
        generator.validate! if generator.respond_to?(:validate!)
        generator.src
      end
    end
  end
end
