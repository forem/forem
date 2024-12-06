module Algolia
  class PaginatorIterator < BaseIterator
    # @param transporter    [Transport::Transport]  transporter used for requests
    # @param index_name    [String]  Name of the index
    # @param opts [Hash] contains extra parameters to send with your query
    #
    def initialize(transporter, index_name, opts)
      super(transporter, index_name, opts)

      @data = {
        hitsPerPage: 1000,
        page: 0
      }
    end

    def each
      loop do
        if @response
          parsed_response = symbolize_hash(@response)
          parsed_data     = symbolize_hash(@data)
          if parsed_response[:hits].length
            parsed_response[:hits].each do |hit|
              hit.delete(:_highlightResult)
              yield hit
            end

            if parsed_response[:nbHits] < parsed_data[:hitsPerPage]
              @response = nil
              @data     = {
                hitsPerPage: 1000,
                page: 0
              }
              raise StopIteration
            end
          end
        end
        @response     = @transporter.read(:POST, get_endpoint, @data, @opts)
        @data[:page] += 1
      end
    end

    def get_endpoint
      raise AlgoliaError, 'Method must be implemented'
    end
  end
end
