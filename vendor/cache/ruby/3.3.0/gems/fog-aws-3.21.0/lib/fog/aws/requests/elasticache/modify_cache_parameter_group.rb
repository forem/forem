module Fog
  module AWS
    class Elasticache
      class Real
        require 'fog/aws/parsers/elasticache/modify_parameter_group'

        # Modifies an existing cache parameter group
        # Returns a the name of the modified parameter group
        #
        # === Required Parameters
        # * id <~String> - The ID of the parameter group to be modified
        # * new_parameters <~Hash> - The parameters to modify, and their values
        # === Returns
        # * response <~Excon::Response>:
        #   * body <~Hash>
        def modify_cache_parameter_group(id, new_parameters)
          # Construct Parameter Modifications in the format:
          #   ParameterNameValues.member.N.ParameterName => "param_name"
          #   ParameterNameValues.member.N.ParameterValue => "param_value"
          n = 0   # n is the parameter index
          parameter_changes = new_parameters.reduce({}) do |new_args,pair|
            n += 1
            new_args["ParameterNameValues.member.#{n}.ParameterName"] = pair[0]
            new_args["ParameterNameValues.member.#{n}.ParameterValue"] = pair[1]
            new_args
          end
          # Merge the Cache Security Group parameters with the normal options
          request(parameter_changes.merge(
            'Action'                      => 'ModifyCacheParameterGroup',
            'CacheParameterGroupName'     => id,
            :parser => Fog::Parsers::AWS::Elasticache::ModifyParameterGroup.new
          ))
        end
      end

      class Mock
        def modify_cache_parameter_group(id, new_parameters)
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
