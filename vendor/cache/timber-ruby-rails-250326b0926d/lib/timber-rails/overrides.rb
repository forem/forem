# The order is relevant
require "timber-rails/overrides/active_support_3_tagged_logging"
require "timber-rails/overrides/active_support_tagged_logging"
require "timber-rails/overrides/active_support_buffered_logger"
require "timber-rails/overrides/lograge"
require "timber-rails/overrides/rails_stdout_logging"

module Timber
  # @private
  module Overrides
  end
end
