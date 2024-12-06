module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/describe_parameter_groups'

        # Returns a list of CacheParameterGroup descriptions
        #
        # === Parameters (optional)
        # * name <~String> - The name of an existing cache parameter group
        # * options <~Hash> (optional):
        # *  :marker <~String> - marker provided in the previous request
        # *  :max_records <~Integer> - the maximum number of records to include
        def describe_cache_parameter_groups(name = nil, options = {})
          request({
            'Action'                  => 'DescribeCacheParameterGroups',
            'CacheParameterGroupName' => name,
            'Marker'                  => options[:marker],
            'MaxRecords'              => options[:max_records],
            :parser => Fog::Parsers::AWS::Elasticache::DescribeParameterGroups.new
          }.merge(options))
        end
      end

      class Mock
        def describe_cache_parameter_groups(name = nil, options = {})
          response = Excon::Response.new
          parameter_set = []
          if name
            if server = self.data[:parameter_groups][name]
              parameter_set << server
            else
              raise Fog::AWS::Elasticache::NotFound.new("CacheParameterGroup #{name} not found")
            end
          else
            parameter_set = self.data[:parameter_groups].values
          end

          response.status = 200

          response.body = { "CacheParameterGroups" => parameter_set }
          response
        end
      end
    end
  end
end
