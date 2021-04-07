module Slack
  class Notifier
    module Util
      class LinkFormatter
        class << self
          def format string, opts={}
            LinkFormatter.new(string, **opts).formatted
          end
        end
      end
    end
  end
end
