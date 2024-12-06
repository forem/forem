module Fog
  module Parsers
    module AWS
      module CloudFormation
        class DescribeStackResources < Fog::Parsers::Base
          def reset
            @resource = {}
            @response = { 'StackResources' => [] }
          end

          def end_element(name)
            case name
            when 'StackId', 'StackName', 'LogicalResourceId', 'PhysicalResourceId', 'ResourceType', 'ResourceStatus'
              @resource[name] = value
            when 'member'
              @response['StackResources'] << @resource
              @resource = {}
            when 'RequestId'
              @response[name] = value
            when 'Timestamp'
              @resource[name] = Time.parse(value)
            end
          end
        end
      end
    end
  end
end
