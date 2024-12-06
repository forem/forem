# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecRails
      # Checks that tests use `have_http_status` instead of equality matchers.
      #
      # @example ResponseMethods: ['response', 'last_response'] (default)
      #   # bad
      #   expect(response.status).to be(200)
      #   expect(last_response.code).to eq("200")
      #
      #   # good
      #   expect(response).to have_http_status(200)
      #   expect(last_response).to have_http_status(200)
      #
      # @example ResponseMethods: ['foo_response']
      #   # bad
      #   expect(foo_response.status).to be(200)
      #
      #   # good
      #   expect(foo_response).to have_http_status(200)
      #
      #   # also good
      #   expect(response).to have_http_status(200)
      #   expect(last_response).to have_http_status(200)
      #
      class HaveHttpStatus < ::RuboCop::Cop::Base
        extend AutoCorrector

        MSG =
          'Prefer `expect(%<response>s).%<to>s ' \
          'have_http_status(%<status>s)` over `%<bad_code>s`.'

        RUNNERS = %i[to to_not not_to].to_set
        RESTRICT_ON_SEND = RUNNERS

        # @!method match_status(node)
        def_node_matcher :match_status, <<~PATTERN
          (send
            (send nil? :expect
              $(send $(send nil? #response_methods?) {:status :code})
            )
            $RUNNERS
            $(send nil? {:be :eq :eql :equal} ({int str} $_))
          )
        PATTERN

        def on_send(node) # rubocop:disable Metrics/MethodLength
          match_status(node) do
            |response_status, response_method, to, match, status|
            return unless status.to_s.match?(/\A\d+\z/)

            message = format(MSG, response: response_method.method_name,
                                  to: to, status: status,
                                  bad_code: node.source)
            add_offense(node, message: message) do |corrector|
              corrector.replace(response_status, response_method.method_name)
              corrector.replace(match.loc.selector, 'have_http_status')
              corrector.replace(match.first_argument, status.to_s)
            end
          end
        end

        private

        def response_methods?(name)
          response_methods.include?(name.to_s)
        end

        def response_methods
          cop_config.fetch('ResponseMethods', [])
        end
      end
    end
  end
end
