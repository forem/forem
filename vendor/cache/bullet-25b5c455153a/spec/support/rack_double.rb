# frozen_string_literal: true

module Support
  class AppDouble
    def call(_env)
      env = @env
      [status, headers, response]
    end

    attr_writer :status

    attr_writer :headers

    def headers
      @headers ||= { 'Content-Type' => 'text/html' }
      @headers
    end

    attr_writer :response

    private

    def status
      @status || 200
    end

    def response
      @response || ResponseDouble.new
    end
  end

  class ResponseDouble
    def initialize(actual_body = nil)
      @actual_body = actual_body
    end

    def body
      @body ||= '<html><head></head><body></body></html>'
    end

    attr_writer :body

    def each
      yield body
    end

    def close; end
  end
end
