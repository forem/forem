require 'fog/aws/models/elasticache/parameter_group'

module Fog
  module AWS
    class Elasticache
      class ParameterGroups < Fog::Collection
        model Fog::AWS::Elasticache::ParameterGroup

        def all
          load(
            service.describe_cache_parameter_groups.body['CacheParameterGroups']
          )
        end

        def get(identity)
          new(
            service.describe_cache_parameter_groups(
              identity
            ).body['CacheParameterGroups'].first
          )
        rescue Fog::AWS::Elasticache::NotFound
          nil
        end
      end
    end
  end
end
