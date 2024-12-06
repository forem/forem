module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/describe_engine_default_parameters'

        # Returns the default engine and system parameter information
        # for the specified cache engine.
        #
        # === Parameters (optional)
        # * options <~Hash>:
        # *  :engine <~String> - the engine whose parameters are requested
        # *  :marker <~String> - marker provided in the previous request
        # *  :max_records <~Integer> - the maximum number of records to include
        def describe_engine_default_parameters(options = {})
          request({
            'Action'                    => 'DescribeEngineDefaultParameters',
            'CacheParameterGroupFamily' => options[:engine] || 'memcached1.4',
            'Marker'                    => options[:marker],
            'MaxRecords'                => options[:max_records],
            :parser => Fog::Parsers::AWS::Elasticache::DescribeEngineDefaultParameters.new
          })
        end
      end

      class Mock
        def describe_engine_defalut_parameters(options = {})
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
