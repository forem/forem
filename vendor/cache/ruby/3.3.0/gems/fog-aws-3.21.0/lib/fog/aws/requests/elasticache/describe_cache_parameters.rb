module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/describe_cache_parameters'

        # Returns a list of CacheParameterGroup descriptions
        #
        # === Parameters (optional)
        # * name <~String> - The name of an existing cache parameter group
        # * options <~Hash> (optional):
        # *  :marker <~String> - marker provided in the previous request
        # *  :max_records <~Integer> - the maximum number of records to include
        # *  :source <~String> - the parameter types to return.
        def describe_cache_parameters(name = nil, options = {})
          request({
            'Action'                  => 'DescribeCacheParameters',
            'CacheParameterGroupName' => name,
            'Marker'                  => options[:marker],
            'MaxRecords'              => options[:max_records],
            'Source'                  => options[:source],
            :parser => Fog::Parsers::AWS::Elasticache::DescribeCacheParameters.new
          })
        end
      end

      class Mock
        def describe_cache_parameters(name = nil, options = {})
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
