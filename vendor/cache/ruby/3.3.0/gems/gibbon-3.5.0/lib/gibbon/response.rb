module Gibbon
  class Response
    attr_accessor :body, :headers
    
    def initialize(body: {}, headers: {})
      @body = body
      @headers = headers
    end 
  end
end
