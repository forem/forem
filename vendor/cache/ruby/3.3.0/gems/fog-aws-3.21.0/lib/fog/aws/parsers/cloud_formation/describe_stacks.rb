module Fog
  module Parsers
    module AWS
      module CloudFormation
        class DescribeStacks < Fog::Parsers::Base
          def reset
            @stack = { 'Outputs' => [], 'Parameters' => [], 'Capabilities' => [], 'Tags' => [] }
            @output = {}
            @parameter = {}
            @tag = {}
            @response = { 'Stacks' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'Outputs'
              @in_outputs = true
            when 'Parameters'
              @in_parameters = true
            when 'Capabilities'
              @in_capabilities = true
            when 'Tags'
              @in_tags = true
            end
          end

          def end_element(name)
            if @in_outputs
              case name
              when 'OutputKey', 'OutputValue', 'Description'
                @output[name] = value
              when 'member'
                @stack['Outputs'] << @output
                @output = {}
              when 'Outputs'
                @in_outputs = false
              end
            elsif @in_parameters
              case name
              when 'ParameterKey', 'ParameterValue'
                @parameter[name] = value
              when 'member'
                @stack['Parameters'] << @parameter
                @parameter = {}
              when 'Parameters'
                @in_parameters = false
              end
            elsif @in_tags
              case name
              when 'Key', 'Value'
                @tag[name] = value
              when 'member'
                @stack['Tags'] << @tag
                @tag = {}
              when 'Tags'
                @in_tags = false
              end
            elsif @in_capabilities
              case name
              when 'member'
                @stack['Capabilities'] << value
              when 'Capabilities'
                @in_capabilities = false
              end
            else
              case name
              when 'member'
                @response['Stacks'] << @stack
                @stack = { 'Outputs' => [], 'Parameters' => [], 'Capabilities' => [], 'Tags' => []}
              when 'RequestId'
                @response[name] = value
              when 'CreationTime'
                @stack[name] = Time.parse(value)
              when 'DisableRollback'
                case value
                when 'false'
                  @stack[name] = false
                when 'true'
                  @stack[name] = true
                end
              when 'StackName', 'StackId', 'StackStatus'
                @stack[name] = value
              end
            end
          end
        end
      end
    end
  end
end
