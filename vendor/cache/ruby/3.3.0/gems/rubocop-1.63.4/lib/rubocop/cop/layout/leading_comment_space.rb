# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks whether comments have a leading space after the
      # `#` denoting the start of the comment. The leading space is not
      # required for some RDoc special syntax, like `#++`, `#--`,
      # `#:nodoc`, `=begin`- and `=end` comments, "shebang" directives,
      # or rackup options.
      #
      # @example
      #
      #   # bad
      #   #Some comment
      #
      #   # good
      #   # Some comment
      #
      # @example AllowDoxygenCommentStyle: false (default)
      #
      #   # bad
      #
      #   #**
      #   # Some comment
      #   # Another line of comment
      #   #*
      #
      # @example AllowDoxygenCommentStyle: true
      #
      #   # good
      #
      #   #**
      #   # Some comment
      #   # Another line of comment
      #   #*
      #
      # @example AllowGemfileRubyComment: false (default)
      #
      #   # bad
      #
      #   #ruby=2.7.0
      #   #ruby-gemset=myproject
      #
      # @example AllowGemfileRubyComment: true
      #
      #   # good
      #
      #   #ruby=2.7.0
      #   #ruby-gemset=myproject
      #
      class LeadingCommentSpace < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Missing space after `#`.'

        def on_new_investigation
          processed_source.comments.each do |comment|
            next unless /\A(?!#\+\+|#--)(#+[^#\s=])/.match?(comment.text)
            next if comment.loc.line == 1 && allowed_on_first_line?(comment)
            next if doxygen_comment_style?(comment)
            next if gemfile_ruby_comment?(comment)

            add_offense(comment) do |corrector|
              expr = comment.source_range

              corrector.insert_after(hash_mark(expr), ' ')
            end
          end
        end

        private

        def hash_mark(expr)
          range_between(expr.begin_pos, expr.begin_pos + 1)
        end

        def allowed_on_first_line?(comment)
          shebang?(comment) || (rackup_config_file? && rackup_options?(comment))
        end

        def shebang?(comment)
          comment.text.start_with?('#!')
        end

        def rackup_options?(comment)
          comment.text.start_with?('#\\')
        end

        def rackup_config_file?
          File.basename(processed_source.file_path).eql?('config.ru')
        end

        def allow_doxygen_comment?
          cop_config['AllowDoxygenCommentStyle']
        end

        def doxygen_comment_style?(comment)
          allow_doxygen_comment? && comment.text.start_with?('#*')
        end

        def allow_gemfile_ruby_comment?
          cop_config['AllowGemfileRubyComment']
        end

        def gemfile?
          File.basename(processed_source.file_path).eql?('Gemfile')
        end

        def ruby_comment_in_gemfile?(comment)
          gemfile? && comment.text.start_with?('#ruby')
        end

        def gemfile_ruby_comment?(comment)
          allow_gemfile_ruby_comment? && ruby_comment_in_gemfile?(comment)
        end
      end
    end
  end
end
