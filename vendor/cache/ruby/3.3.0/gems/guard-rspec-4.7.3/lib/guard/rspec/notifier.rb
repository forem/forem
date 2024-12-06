module Guard
  class RSpec < Plugin
    class Notifier
      attr_accessor :options

      def initialize(options = {})
        @options = options
      end

      def notify(summary)
        return unless options[:notification]
        failure_count, pending_count = _parse_summary(summary)
        image = _image(failure_count, pending_count)
        priority = _priority(image)
        Guard::Compat::UI.notify(summary,
                                 title: @options[:title],
                                 image: image,
                                 priority: priority)
      end

      def notify_failure
        return unless options[:notification]
        Guard::Compat::UI.notify("Failed",
                                 title: @options[:title],
                                 image: :failed,
                                 priority: 2)
      end

      private

      def _parse_summary(summary)
        summary.match(/(\d+) failures( \((\d+) pending\))?/) do |m|
          return m[1].to_i, m[3].to_i
        end
        [0, 0]
      end

      def _image(failure_count, pending_count)
        if failure_count > 0
          :failed
        elsif pending_count > 0
          :pending
        else
          :success
        end
      end

      def _priority(image)
        { failed:   2,
          pending: -1,
          success: -2 }[image]
      end
    end
  end
end
