module Fog
  module Parsers
    module AWS
      module CloudFormation
        class GetTemplateSummary < Fog::Parsers::Base
          def reset
            reset_parameter
            @response = {'Capabilities' => [],'ResourceTypes' => '','Parameters' => []  }
          end

          def reset_parameter
            @parameter = {'AllowedValues' => []}
          end

          def start_element(name, attrs=[])
            super
            case name
            when 'Capabilities'
              @in_capabilities = true
            when 'Parameters'
              @in_parameters = true
            when 'ResourceTypes'
              @in_resource_types = true
            end
          end

          def end_element(name)
            case name
            when 'member'
              if @in_capabilities
                @response['Capabilities'] << value
              elsif @in_resource_types
                @response['ResourceTypes'] << value
              elsif @in_parameters
                @response['Parameters'] << @parameter
                reset_parameter
              end
            when 'DefaultValue', 'NoEcho', 'ParameterKey', 'ParameterType', 'ParameterType'
              @parameter[name] = value if @in_parameters
            when 'Description'
              if @in_parameters
                @parameter[name] = value
              else
                @response[name] = value
              end
            when 'ParameterConstraints'
              @parameter['AllowedValues'] << value  if @in_parameters
            when 'RequestId'
              @response[name] = value
            when 'Parameters'
              @in_parameters = false
            when 'ResourceTypes'
              @in_resource_types = false
            when 'Capabilities'
              @in_capabilities = false
            end
          end
        end
      end
    end
  end
end
