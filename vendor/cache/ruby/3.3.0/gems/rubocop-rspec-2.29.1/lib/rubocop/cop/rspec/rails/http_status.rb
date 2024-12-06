# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module Rails
        # @!parse
        #   # Enforces use of symbolic or numeric value to describe HTTP status.
        #   #
        #   # This cop inspects only `have_http_status` calls.
        #   # So, this cop does not check if a method starting with `be_*` is
        #   # used when setting for `EnforcedStyle: symbolic` or
        #   # `EnforcedStyle: numeric`.
        #   #
        #   # @example `EnforcedStyle: symbolic` (default)
        #   #   # bad
        #   #   it { is_expected.to have_http_status 200 }
        #   #   it { is_expected.to have_http_status 404 }
        #   #   it { is_expected.to have_http_status "403" }
        #   #
        #   #   # good
        #   #   it { is_expected.to have_http_status :ok }
        #   #   it { is_expected.to have_http_status :not_found }
        #   #   it { is_expected.to have_http_status :forbidden }
        #   #   it { is_expected.to have_http_status :success }
        #   #   it { is_expected.to have_http_status :error }
        #   #
        #   # @example `EnforcedStyle: numeric`
        #   #   # bad
        #   #   it { is_expected.to have_http_status :ok }
        #   #   it { is_expected.to have_http_status :not_found }
        #   #   it { is_expected.to have_http_status "forbidden" }
        #   #
        #   #   # good
        #   #   it { is_expected.to have_http_status 200 }
        #   #   it { is_expected.to have_http_status 404 }
        #   #   it { is_expected.to have_http_status 403 }
        #   #   it { is_expected.to have_http_status :success }
        #   #   it { is_expected.to have_http_status :error }
        #   #
        #   # @example `EnforcedStyle: be_status`
        #   #   # bad
        #   #   it { is_expected.to have_http_status :ok }
        #   #   it { is_expected.to have_http_status :not_found }
        #   #   it { is_expected.to have_http_status "forbidden" }
        #   #   it { is_expected.to have_http_status 200 }
        #   #   it { is_expected.to have_http_status 404 }
        #   #   it { is_expected.to have_http_status "403" }
        #   #
        #   #   # good
        #   #   it { is_expected.to be_ok }
        #   #   it { is_expected.to be_not_found }
        #   #   it { is_expected.to have_http_status :success }
        #   #   it { is_expected.to have_http_status :error }
        #   #
        #   class HttpStatus < RuboCop::Cop::RSpec::Base; end
        HttpStatus = ::RuboCop::Cop::RSpecRails::HttpStatus
      end
    end
  end
end
