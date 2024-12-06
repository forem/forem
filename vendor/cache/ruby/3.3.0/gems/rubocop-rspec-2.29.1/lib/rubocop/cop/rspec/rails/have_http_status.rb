# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module Rails
        # @!parse
        #   # Checks that tests use `have_http_status` instead of equality matchers.
        #   #
        #   # @example ResponseMethods: ['response', 'last_response'] (default)
        #   #   # bad
        #   #   expect(response.status).to be(200)
        #   #   expect(last_response.code).to eq("200")
        #   #
        #   #   # good
        #   #   expect(response).to have_http_status(200)
        #   #   expect(last_response).to have_http_status(200)
        #   #
        #   # @example ResponseMethods: ['foo_response']
        #   #   # bad
        #   #   expect(foo_response.status).to be(200)
        #   #
        #   #   # good
        #   #   expect(foo_response).to have_http_status(200)
        #   #
        #   #   # also good
        #   #   expect(response).to have_http_status(200)
        #   #   expect(last_response).to have_http_status(200)
        #   #
        #   class HaveHttpStatus < ::RuboCop::Cop::Base; end
        HaveHttpStatus = ::RuboCop::Cop::RSpecRails::HaveHttpStatus
      end
    end
  end
end
