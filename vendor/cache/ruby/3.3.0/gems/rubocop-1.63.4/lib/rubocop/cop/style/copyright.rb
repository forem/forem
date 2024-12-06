# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Check that a copyright notice was given in each source file.
      #
      # The default regexp for an acceptable copyright notice can be found in
      # config/default.yml. The default can be changed as follows:
      #
      # [source,yaml]
      # ----
      # Style/Copyright:
      #   Notice: '^Copyright (\(c\) )?2\d{3} Acme Inc'
      # ----
      #
      # This regex string is treated as an unanchored regex. For each file
      # that RuboCop scans, a comment that matches this regex must be found or
      # an offense is reported.
      #
      class Copyright < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Include a copyright notice matching /%<notice>s/ before any code.'
        AUTOCORRECT_EMPTY_WARNING = 'An AutocorrectNotice must be defined in your RuboCop config'

        def on_new_investigation
          return if notice.empty? || notice_found?(processed_source)

          verify_autocorrect_notice!
          message = format(MSG, notice: notice)
          if processed_source.blank?
            add_global_offense(message)
          else
            offense_range = source_range(processed_source.buffer, 1, 0)
            add_offense(offense_range, message: message) do |corrector|
              autocorrect(corrector)
            end
          end
        end

        private

        def autocorrect(corrector)
          token = insert_notice_before(processed_source)
          range = token.nil? ? range_between(0, 0) : token.pos

          corrector.insert_before(range, "#{autocorrect_notice}\n")
        end

        def notice
          cop_config['Notice']
        end

        def autocorrect_notice
          cop_config['AutocorrectNotice']
        end

        def verify_autocorrect_notice!
          raise Warning, AUTOCORRECT_EMPTY_WARNING if autocorrect_notice.empty?

          regex = Regexp.new(notice)
          return if autocorrect_notice&.match?(regex)

          raise Warning, "AutocorrectNotice '#{autocorrect_notice}' must match Notice /#{notice}/"
        end

        def insert_notice_before(processed_source)
          token_index = 0
          token_index += 1 if shebang_token?(processed_source, token_index)
          token_index += 1 if encoding_token?(processed_source, token_index)
          processed_source.tokens[token_index]
        end

        def shebang_token?(processed_source, token_index)
          return false if token_index >= processed_source.tokens.size

          token = processed_source.tokens[token_index]
          token.comment? && /^#!.*$/.match?(token.text)
        end

        def encoding_token?(processed_source, token_index)
          return false if token_index >= processed_source.tokens.size

          token = processed_source.tokens[token_index]
          token.comment? && /^#.*coding\s?[:=]\s?(?:UTF|utf)-8/.match?(token.text)
        end

        def notice_found?(processed_source)
          notice_found = false
          notice_regexp = Regexp.new(notice)
          processed_source.tokens.each do |token|
            break unless token.comment?

            notice_found = notice_regexp.match?(token.text)
            break if notice_found
          end
          notice_found
        end
      end
    end
  end
end
