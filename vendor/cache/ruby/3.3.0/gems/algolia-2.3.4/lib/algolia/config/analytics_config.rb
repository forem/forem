module Algolia
  module Analytics
    class Config < BaseConfig
      attr_accessor :region, :default_hosts

      # Initialize a config
      #
      # @option options [String] :application_id
      # @option options [String] :api_key
      # @option options [String] :region
      #
      def initialize(opts = {})
        super(opts)

        @region        = opts[:region] || 'us'
        @default_hosts = [Transport::StatefulHost.new("analytics.#{region}.algolia.com")]
      end
    end
  end
end
