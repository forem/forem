module Fog
  module Parsers
    module AWS
      module CloudFormation
        class ValidateTemplate < Fog::Parsers::Base
          def reset
            @parameter = {}
            @response = { 'Parameters' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'Parameters'
              @in_parameters = true
            end
          end

          def end_element(name)
            case name
            when 'DefaultValue', 'ParameterKey'
              @parameter[name] = value
            when 'Description'
              if @in_parameters
                @parameter[name] = value
              else
                @response[name] = value
              end
            when 'RequestId'
              @response[name] = value
            when 'member'
              @response['Parameters'] << @parameter
              @parameter = {}
            when 'NoEcho'
              case value
              when 'false'
                @parameter[name] = false
              when 'true'
                @parameter[name] = true
              end
            when 'Parameters'
              @in_parameters = false
            end
          end
        end
      end
    end
  end
end
