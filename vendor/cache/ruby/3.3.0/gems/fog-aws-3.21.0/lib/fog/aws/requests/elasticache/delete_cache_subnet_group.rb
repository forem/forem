module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/base'

        # deletes a cache subnet group
        #
        # === Parameters
        # * name <~String> - The name for the Cache Subnet Group
        # === Returns
        # * response <~Excon::Response>:
        #   * body <~Hash>
        def delete_cache_subnet_group(name)
          request({
            'Action' => 'DeleteCacheSubnetGroup',
            'CacheSubnetGroupName' => name,
            :parser => Fog::Parsers::AWS::Elasticache::Base.new
          })
        end
      end

      class Mock
        def delete_cache_subnet_group(name)
          if self.data[:subnet_groups].delete(name)
            Excon::Response.new(
                {
                    :status => 200,
                    :body =>   { 'ResponseMetadata'=>{ 'RequestId'=> Fog::AWS::Mock.request_id } }
                }
            )
          else
            raise Fog::AWS::Elasticache::NotFound.new("CacheSubnetGroupNotFound => #{name} not found")
          end
        end
      end
    end
  end
end
