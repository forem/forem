module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/single_parameter_group'

        # creates a cache parameter group
        #
        # === Parameters
        # * name <~String> - The name for the Cache Parameter Group
        # === Optional Parameters
        # * description <~String> - The description for the Cache Parameter Group
        # * family <~String> - The description for the Cache Parameter Group
        # === Returns
        # * response <~Excon::Response>:
        #   * body <~Hash>
        def create_cache_parameter_group(name, description = name, family = 'memcached1.4')
          request({
            'Action' => 'CreateCacheParameterGroup',
            'CacheParameterGroupName' => name,
            'Description' => description,
            'CacheParameterGroupFamily' => family,
            :parser => Fog::Parsers::AWS::Elasticache::SingleParameterGroup.new
          })
        end
      end

      class Mock
        def create_cache_parameter_group(name, description = name, family = 'memcached1.4')
          response = Excon::Response.new
          if self.data[:parameter_groups] and self.data[:parameter_groups][name]
            raise Fog::AWS::Elasticache::IdentifierTaken.new("Parameter group #{name} already exists")
          end

          data = {
            'CacheParameterGroupName' => name,
            'CacheParameterGroupFamily' => family.downcase,
            'Description' => description
          }
          self.data[:parameter_groups][name] = data

          response.body = {
            "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id },
            "CreateCacheParameterGroupResult"=> {"CacheParameterGroup"=> data}
          }
          response.status = 200
          response
        end
      end
    end
  end
end
