module NetHttp2

  class Response
    attr_reader :headers, :body

    def initialize(options={})
      @headers = options[:headers]
      @body    = options[:body]
    end

    def status
      @headers[':status'] if @headers
    end

    def ok?
      status == '200'
    end
  end
end
