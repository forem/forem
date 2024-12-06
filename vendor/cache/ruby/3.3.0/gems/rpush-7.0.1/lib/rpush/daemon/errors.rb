module Rpush
  class CertificateExpiredError < StandardError
    attr_reader :app, :time

    def initialize(app, time)
      @app = app
      @time = time
    end

    def to_s
      message
    end

    def message
      "#{app.name} certificate expired at #{time}."
    end
  end
end
