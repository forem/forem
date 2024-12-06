
module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/single_security_group'

        # Revoke ingress to a CacheSecurityGroup using EC2 Security Groups
        #
        # === Parameters
        # * name <~String> - The name of the cache security group
        # * ec2_name <~String> - The name of the EC2 security group to revoke
        # * ec2_owner_id <~String> - The AWS Account Number of the EC2 security group
        # === Returns
        # * response <~Excon::Response>:
        #   * body <~Hash>
        def revoke_cache_security_group_ingress(name, ec2_name, ec2_owner_id)
          request({
            'Action' => 'RevokeCacheSecurityGroupIngress',
            'CacheSecurityGroupName' => name,
            'EC2SecurityGroupName' => ec2_name,
            'EC2SecurityGroupOwnerId' => ec2_owner_id,
            :parser => Fog::Parsers::AWS::Elasticache::SingleSecurityGroup.new
          })
        end
      end

      class Mock
        def revoke_cache_security_group_ingress
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
