# frozen_string_literal: true

module KnapsackPro
  class Presenter
    class << self
      def global_time
        global_time = pretty_seconds(KnapsackPro.tracker.global_time)
        "Global time execution for tests: #{global_time}"
      end

      def pretty_seconds(seconds)
        sign = ''

        if seconds < 0
          seconds = seconds*-1
          sign = '-'
        end

        return "#{sign}#{seconds}s" if seconds.abs < 1

        time = Time.at(seconds).gmtime.strftime('%Hh %Mm %Ss')
        time_without_zeros = time.gsub(/00(h|m|s)/, '').strip
        sign + time_without_zeros
      end
    end
  end
end
