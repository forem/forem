# frozen_string_literal: true

require "better_html/parser"
require "better_html/test_helper/safety_error"
require "better_html/test_helper/safe_erb/base"
require "better_html/test_helper/safe_erb/no_statements"
require "better_html/test_helper/safe_erb/allowed_script_type"
require "better_html/test_helper/safe_erb/no_javascript_tag_helper"
require "better_html/test_helper/safe_erb/tag_interpolation"
require "better_html/test_helper/safe_erb/script_interpolation"
require "better_html/tree/tag"

module BetterHtml
  module TestHelper
    module SafeErbTester
      SAFETY_TIPS = <<~EOF
        -----------

        The javascript snippets listed above do not appear to be escaped properly
        in a javascript context. Here are some tips:

        Never use html_safe inside a html tag, since it is _never_ safe:
          <a href="<%= value.html_safe %>">
                            ^^^^^^^^^^

        Always use .to_json for html attributes which contain javascript, like 'onclick',
        or twine attributes like 'data-define', 'data-context', 'data-eval', 'data-bind', etc:
          <div onclick="<%= value.to_json %>">
                                 ^^^^^^^^

        Always use raw and to_json together within <script> tags:
          <script type="text/javascript">
            var yourValue = <%= raw value.to_json %>;
          </script>             ^^^      ^^^^^^^^

        -----------
      EOF

      def assert_erb_safety(data, **options)
        options = options.present? ? options.dup : {}
        options[:template_language] ||= :html
        buffer = ::Parser::Source::Buffer.new(options[:filename] || "(buffer)")
        buffer.source = data
        parser = BetterHtml::Parser.new(buffer, **options)

        tester_classes = [
          SafeErb::NoStatements,
          SafeErb::AllowedScriptType,
          SafeErb::NoJavascriptTagHelper,
          SafeErb::ScriptInterpolation,
        ]
        if options[:template_language] == :html
          tester_classes << SafeErb::TagInterpolation
        end

        testers = tester_classes.map do |tester_klass|
          tester_klass.new(parser)
        end
        testers.each(&:validate)
        errors = testers.map(&:errors).flatten

        messages = errors.map do |error|
          <<~EOL
            In #{buffer.name}:#{error.location.line}
            #{error.message}
            #{error.location.line_source_with_underline}\n
          EOL
        end
        messages << SAFETY_TIPS

        assert_predicate(errors, :empty?, messages.join)
      end
    end
  end
end
