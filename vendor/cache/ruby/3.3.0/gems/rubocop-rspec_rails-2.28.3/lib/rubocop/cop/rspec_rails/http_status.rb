# frozen_string_literal: true

begin
  require 'rack/utils'
rescue LoadError
  # RSpecRails/HttpStatus cannot be loaded if rack/utils is unavailable.
end

module RuboCop
  module Cop
    module RSpecRails
      # Enforces use of symbolic or numeric value to describe HTTP status.
      #
      # This cop inspects only `have_http_status` calls.
      # So, this cop does not check if a method starting with `be_*` is used
      # when setting for `EnforcedStyle: symbolic` or
      # `EnforcedStyle: numeric`.
      #
      # @example `EnforcedStyle: symbolic` (default)
      #   # bad
      #   it { is_expected.to have_http_status 200 }
      #   it { is_expected.to have_http_status 404 }
      #   it { is_expected.to have_http_status "403" }
      #
      #   # good
      #   it { is_expected.to have_http_status :ok }
      #   it { is_expected.to have_http_status :not_found }
      #   it { is_expected.to have_http_status :forbidden }
      #   it { is_expected.to have_http_status :success }
      #   it { is_expected.to have_http_status :error }
      #
      # @example `EnforcedStyle: numeric`
      #   # bad
      #   it { is_expected.to have_http_status :ok }
      #   it { is_expected.to have_http_status :not_found }
      #   it { is_expected.to have_http_status "forbidden" }
      #
      #   # good
      #   it { is_expected.to have_http_status 200 }
      #   it { is_expected.to have_http_status 404 }
      #   it { is_expected.to have_http_status 403 }
      #   it { is_expected.to have_http_status :success }
      #   it { is_expected.to have_http_status :error }
      #
      # @example `EnforcedStyle: be_status`
      #   # bad
      #   it { is_expected.to have_http_status :ok }
      #   it { is_expected.to have_http_status :not_found }
      #   it { is_expected.to have_http_status "forbidden" }
      #   it { is_expected.to have_http_status 200 }
      #   it { is_expected.to have_http_status 404 }
      #   it { is_expected.to have_http_status "403" }
      #
      #   # good
      #   it { is_expected.to be_ok }
      #   it { is_expected.to be_not_found }
      #   it { is_expected.to have_http_status :success }
      #   it { is_expected.to have_http_status :error }
      #
      class HttpStatus < ::RuboCop::Cop::Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle
        RESTRICT_ON_SEND = %i[have_http_status].freeze

        # @!method http_status(node)
        def_node_matcher :http_status, <<~PATTERN
          (send nil? :have_http_status ${int sym str})
        PATTERN

        def on_send(node)
          return unless defined?(::Rack::Utils::SYMBOL_TO_STATUS_CODE)

          http_status(node) do |arg|
            return if arg.str_type? && arg.heredoc?

            checker = checker_class.new(arg)
            return unless checker.offensive?

            add_offense(checker.offense_range,
                        message: checker.message) do |corrector|
              corrector.replace(checker.offense_range, checker.prefer)
            end
          end
        end

        private

        def checker_class
          case style
          when :symbolic
            SymbolicStyleChecker
          when :numeric
            NumericStyleChecker
          when :be_status
            BeStatusStyleChecker
          end
        end

        # :nodoc:
        class StyleCheckerBase
          MSG = 'Prefer `%<prefer>s` over `%<current>s` ' \
                'to describe HTTP status code.'
          ALLOWED_STATUSES = %i[error success missing redirect].freeze

          attr_reader :node

          def initialize(node)
            @node = node
          end

          def message
            format(MSG, prefer: prefer, current: current)
          end

          def current
            offense_range.source
          end

          def offense_range
            node
          end

          def allowed_symbol?
            node.sym_type? && ALLOWED_STATUSES.include?(node.value)
          end

          def custom_http_status_code?
            node.int_type? &&
              !::Rack::Utils::SYMBOL_TO_STATUS_CODE.value?(node.source.to_i)
          end
        end

        # :nodoc:
        class SymbolicStyleChecker < StyleCheckerBase
          def offensive?
            !node.sym_type? && !custom_http_status_code?
          end

          def prefer
            symbol.inspect
          end

          private

          def symbol
            ::Rack::Utils::SYMBOL_TO_STATUS_CODE.key(number)
          end

          def number
            node.value.to_i
          end
        end

        # :nodoc:
        class NumericStyleChecker < StyleCheckerBase
          def offensive?
            !node.int_type? && !allowed_symbol?
          end

          def prefer
            number.to_s
          end

          private

          def symbol
            node.value
          end

          def number
            ::Rack::Utils::SYMBOL_TO_STATUS_CODE[symbol.to_sym]
          end
        end

        # :nodoc:
        class BeStatusStyleChecker < StyleCheckerBase
          def offensive?
            (!node.sym_type? && !custom_http_status_code?) ||
              (!node.int_type? && !allowed_symbol?)
          end

          def offense_range
            node.parent
          end

          def prefer
            if node.sym_type?
              "be_#{node.value}"
            elsif node.int_type?
              "be_#{symbol}"
            elsif node.str_type?
              "be_#{normalize_str}"
            end
          end

          private

          def symbol
            ::Rack::Utils::SYMBOL_TO_STATUS_CODE.key(number)
          end

          def number
            node.value.to_i
          end

          def normalize_str
            str = node.value.to_s
            if str.match?(/\A\d+\z/)
              ::Rack::Utils::SYMBOL_TO_STATUS_CODE.key(str.to_i)
            else
              str
            end
          end
        end
      end
    end
  end
end
