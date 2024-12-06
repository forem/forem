module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/base'

        # deletes a cache parameter group
        #
        # === Parameters
        # * name <~String> - The name for the Cache Parameter Group
        # === Returns
        # * response <~Excon::Response>:
        #   * body <~Hash>
        def delete_cache_parameter_group(name)
          request({
            'Action' => 'DeleteCacheParameterGroup',
            'CacheParameterGroupName' => name,
            :parser => Fog::Parsers::AWS::Elasticache::Base.new
          })
        end
      end

      class Mock
        def delete_cache_parameter_group(name)
          response = Excon::Response.new

          if self.data[:parameter_groups].delete(name)
            response.status = 200
            response.body = {
              "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id },
            }
            response
          else
            raise Fog::AWS::Elasticache::NotFound.new("CacheParameterGroup not found: #{name}")
          end
        end
      end
    end
  end
end
