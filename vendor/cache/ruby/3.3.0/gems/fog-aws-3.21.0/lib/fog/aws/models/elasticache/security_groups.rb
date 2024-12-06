require 'fog/aws/models/elasticache/security_group'

module Fog
  module AWS
    class Elasticache
      class SecurityGroups < Fog::Collection
        model Fog::AWS::Elasticache::SecurityGroup

        def all
          load(
            service.describe_cache_security_groups.body['CacheSecurityGroups']
          )
        end

        def get(identity)
          new(
            service.describe_cache_security_groups(
              identity
            ).body['CacheSecurityGroups'].first
          )
        rescue Fog::AWS::Elasticache::NotFound
          nil
        end
      end
    end
  end
end
