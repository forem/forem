module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/single_security_group'

        # creates a cache security group
        #
        # === Parameters
        # * name <~String> - The name for the Cache Security Group
        # * description <~String> - The description for the Cache Security Group
        # === Returns
        # * response <~Excon::Response>:
        #   * body <~Hash>
        def create_cache_security_group(name, description = name)
          request({
            'Action' => 'CreateCacheSecurityGroup',
            'CacheSecurityGroupName' => name,
            'Description' => description,
            :parser => Fog::Parsers::AWS::Elasticache::SingleSecurityGroup.new
          })
        end
      end

      class Mock
        def create_cache_security_group(name, description = name)
          if self.data[:security_groups][name]
            raise Fog::AWS::Elasticache::IdentifierTaken.new("CacheClusterAlreadyExists => The security group '#{name}' already exists")
          end

          data = {
            'CacheSecurityGroupName' => name,
            'Description' => description,
            'EC2SecurityGroups' => [],
            'OwnerId' => '0123456789'
          }
          self.data[:security_groups][name] = data

          Excon::Response.new(
              {
                  :body => {
                      'ResponseMetadata'=>{ 'RequestId'=> Fog::AWS::Mock.request_id },
                      'CacheSecurityGroup' => data
                  }
              }
          )
        end
      end
    end
  end
end
