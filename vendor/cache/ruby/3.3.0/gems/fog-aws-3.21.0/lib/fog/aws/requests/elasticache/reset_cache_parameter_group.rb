module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/reset_parameter_group'

        # Resets an existing cache parameter group
        # Returns a the name of the modified parameter group
        #
        # === Required Parameters
        # * id <~String> - The ID of the parameter group to be modified
        # === Optional Parameters
        # * parameter_names <~Array> - The parameters to reset
        # === Returns
        # * response <~Excon::Response>:
        #   * body <~Hash>
        def reset_cache_parameter_group(id, parameter_names = [])
          # Construct Parameter resets in the format:
          #   ParameterNameValues.member.N => "param_name"
          parameter_changes = parameter_names.reduce({}) do |new_args, param|
            index = parameter_names.index(param) + 1
            new_args["ParameterNameValues.member.#{index}"] = param
            new_args
          end
          if parameter_changes.empty?
            parameter_changes = {'ResetAllParameters' => 'true'}
          end
          # Merge the Cache Security Group parameters with the normal options
          request(parameter_changes.merge(
            'Action'                      => 'ResetCacheParameterGroup',
            'CacheParameterGroupName'     => id,
            :parser => Fog::Parsers::AWS::Elasticache::ResetParameterGroup.new
          ))
        end
      end

      class Mock
        def reset_cache_parameter_group(id, parameter_names)
           Fog::Mock.not_implemented
        end
      end
    end
  end
end
