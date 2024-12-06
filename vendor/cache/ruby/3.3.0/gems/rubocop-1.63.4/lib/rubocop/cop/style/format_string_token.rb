# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Use a consistent style for named format string tokens.
      #
      # NOTE: `unannotated` style cop only works for strings
      # which are passed as arguments to those methods:
      # `printf`, `sprintf`, `format`, `%`.
      # The reason is that _unannotated_ format is very similar
      # to encoded URLs or Date/Time formatting strings.
      #
      # This cop can be customized allowed methods with `AllowedMethods`.
      # By default, there are no methods to allowed.
      #
      # @example EnforcedStyle: annotated (default)
      #
      #   # bad
      #   format('%{greeting}', greeting: 'Hello')
      #   format('%s', 'Hello')
      #
      #   # good
      #   format('%<greeting>s', greeting: 'Hello')
      #
      # @example EnforcedStyle: template
      #
      #   # bad
      #   format('%<greeting>s', greeting: 'Hello')
      #   format('%s', 'Hello')
      #
      #   # good
      #   format('%{greeting}', greeting: 'Hello')
      #
      # @example EnforcedStyle: unannotated
      #
      #   # bad
      #   format('%<greeting>s', greeting: 'Hello')
      #   format('%{greeting}', greeting: 'Hello')
      #
      #   # good
      #   format('%s', 'Hello')
      #
      # It is allowed to contain unannotated token
      # if the number of them is less than or equals to
      # `MaxUnannotatedPlaceholdersAllowed`.
      #
      # @example MaxUnannotatedPlaceholdersAllowed: 0
      #
      #   # bad
      #   format('%06d', 10)
      #   format('%s %s.', 'Hello', 'world')
      #
      #   # good
      #   format('%<number>06d', number: 10)
      #
      # @example MaxUnannotatedPlaceholdersAllowed: 1 (default)
      #
      #   # bad
      #   format('%s %s.', 'Hello', 'world')
      #
      #   # good
      #   format('%06d', 10)
      #
      # @example AllowedMethods: [] (default)
      #
      #   # bad
      #   redirect('foo/%{bar_id}')
      #
      # @example AllowedMethods: [redirect]
      #
      #   # good
      #   redirect('foo/%{bar_id}')
      #
      # @example AllowedPatterns: [] (default)
      #
      #   # bad
      #   redirect('foo/%{bar_id}')
      #
      # @example AllowedPatterns: ['redirect']
      #
      #   # good
      #   redirect('foo/%{bar_id}')
      #
      class FormatStringToken < Base
        include ConfigurableEnforcedStyle
        include AllowedMethods
        include AllowedPattern
        extend AutoCorrector

        def on_str(node)
          return if format_string_token?(node) || use_allowed_method?(node)

          detections = collect_detections(node)
          return if detections.empty?
          return if allowed_unannotated?(detections)

          detections.each do |detected_sequence, token_range|
            check_sequence(detected_sequence, token_range)
          end
        end

        private

        # @!method format_string_in_typical_context?(node)
        def_node_matcher :format_string_in_typical_context?, <<~PATTERN
          {
            ^(send _ {:format :sprintf :printf} %0 ...)
            ^(send %0 :% _)
          }
        PATTERN

        def format_string_token?(node)
          !node.value.include?('%') || node.each_ancestor(:xstr, :regexp).any?
        end

        def use_allowed_method?(node)
          send_parent = node.each_ancestor(:send).first
          send_parent &&
            (allowed_method?(send_parent.method_name) ||
            matches_allowed_pattern?(send_parent.method_name))
        end

        def check_sequence(detected_sequence, token_range)
          if detected_sequence.style == style
            correct_style_detected
          elsif correctable_sequence?(detected_sequence.type)
            style_detected(detected_sequence.style)
            add_offense(token_range, message: message(detected_sequence.style)) do |corrector|
              autocorrect_sequence(corrector, detected_sequence, token_range)
            end
          end
        end

        def correctable_sequence?(detected_type)
          detected_type == 's' || style == :annotated || style == :unannotated
        end

        def autocorrect_sequence(corrector, detected_sequence, token_range)
          return if style == :unannotated

          name = detected_sequence.name
          return if name.nil?

          flags = detected_sequence.flags
          width = detected_sequence.width
          precision = detected_sequence.precision
          type = detected_sequence.style == :template ? 's' : detected_sequence.type
          correction = case style
                       when :annotated then "%<#{name}>#{flags}#{width}#{precision}#{type}"
                       when :template then "%#{flags}#{width}#{precision}{#{name}}"
                       end
          corrector.replace(token_range, correction)
        end

        def unannotated_format?(node, detected_style)
          detected_style == :unannotated && !format_string_in_typical_context?(node)
        end

        def message(detected_style)
          "Prefer #{message_text(style)} over #{message_text(detected_style)}."
        end

        # rubocop:disable Style/FormatStringToken
        def message_text(style)
          {
            annotated: 'annotated tokens (like `%<foo>s`)',
            template: 'template tokens (like `%{foo}`)',
            unannotated: 'unannotated tokens (like `%s`)'
          }[style]
        end
        # rubocop:enable Style/FormatStringToken

        def tokens(str_node, &block)
          return if str_node.source == '__FILE__'

          token_ranges(str_contents(str_node.loc), &block)
        end

        def str_contents(source_map)
          if source_map.is_a?(Parser::Source::Map::Heredoc)
            source_map.heredoc_body
          elsif source_map.begin
            source_map.expression.adjust(begin_pos: +1, end_pos: -1)
          else
            source_map.expression
          end
        end

        def token_ranges(contents)
          format_string = RuboCop::Cop::Utils::FormatString.new(contents.source)

          format_string.format_sequences.each do |detected_sequence|
            next if detected_sequence.percent?

            token = contents.begin.adjust(begin_pos: detected_sequence.begin_pos,
                                          end_pos: detected_sequence.end_pos)

            yield(detected_sequence, token)
          end
        end

        def collect_detections(node)
          detections = []
          tokens(node) do |detected_sequence, token_range|
            unless unannotated_format?(node, detected_sequence.style)
              detections << [detected_sequence, token_range]
            end
          end
          detections
        end

        def allowed_unannotated?(detections)
          return false unless detections.all? do |detected_sequence,|
                                detected_sequence.style == :unannotated
                              end
          return true if detections.size <= max_unannotated_placeholders_allowed

          detections.any? { |detected_sequence,| !correctable_sequence?(detected_sequence.type) }
        end

        def max_unannotated_placeholders_allowed
          cop_config['MaxUnannotatedPlaceholdersAllowed']
        end
      end
    end
  end
end
