module Twitter
  module Streaming
    class StallWarning < Twitter::Base
      attr_reader :code, :message, :percent_full
    end
  end
end
