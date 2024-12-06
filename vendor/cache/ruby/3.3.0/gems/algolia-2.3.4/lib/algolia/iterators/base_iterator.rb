module Algolia
  class BaseIterator
    include Helpers
    include Enumerable

    attr_reader :transporter, :index_name, :opts

    # @param transporter    [Transport::Transport]  transporter used for requests
    # @param index_name    [String]  Name of the index
    # @param opts [Hash] contains extra parameters to send with your query
    #
    def initialize(transporter, index_name, opts)
      @transporter = transporter
      @index_name  = index_name
      @opts        = opts
      @response    = nil
    end
  end
end
