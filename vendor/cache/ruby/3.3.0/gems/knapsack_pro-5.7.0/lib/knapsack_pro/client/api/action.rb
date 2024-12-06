# frozen_string_literal: true

module KnapsackPro
  module Client
    module API
      class Action
        attr_reader :endpoint_path, :http_method, :request_hash

        def initialize(args)
          @endpoint_path = args.fetch(:endpoint_path)
          @http_method = args.fetch(:http_method)
          @request_hash = args.fetch(:request_hash)
        end
      end
    end
  end
end
