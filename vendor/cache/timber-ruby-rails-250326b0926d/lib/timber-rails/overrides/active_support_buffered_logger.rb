# This adds a #formatter and #formatter= method to the legacy ActiveSupport::BufferedLogger
# class. This bug was never resolved due to it being phased out past Rails >= 4.

begin
  require "active_support/buffered_logger"

  class ActiveSupport::BufferedLogger
    def formatter
      if @log.respond_to?(:formatter)
        @log.formatter
      end
    end

    def formatter=(value)
      if @log.respond_to?(:formatter=)
        @log.formatter = value
      end
    end
  end

rescue Exception
end