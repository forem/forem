module Algolia
  class ObjectIterator < BaseIterator
    # Custom each function to iterate through the objects
    #
    def each
      loop do
        data = {}

        if @response
          parsed_response = symbolize_hash(@response)
          if parsed_response[:hits].length
            parsed_response[:hits].each do |hit|
              yield hit
            end

            if parsed_response[:cursor].nil?
              @response = nil
              raise StopIteration
            else
              data[:cursor] = parsed_response[:cursor]
            end
          end
        end
        @response = @transporter.read(:POST, path_encode('1/indexes/%s/browse', @index_name), data, @opts)
      end
    end
  end
end
