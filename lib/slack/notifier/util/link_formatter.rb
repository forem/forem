module Slack
  class Notifier
    module Util
      class LinkFormatter
        class << self
          # rubocop:disable Style/OptionHash
          def format(string, opts = {})
            LinkFormatter.new(string, **opts).formatted
          end
          # rubocop:enable Style/OptionHash
        end
      end
    end
  end
end
