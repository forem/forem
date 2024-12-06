module Fog
  module Parsers
    module AWS
      module CloudFormation
        class DescribeStackResource < Fog::Parsers::Base
          def reset
            @resource = {}
            @response = { 'StackResourceDetail' => {} }
          end

          def end_element(name)
            case name
            when 'Description','LogicalResourceId', 'Metadata', 'PhysicalResourceId', 'ResourceStatus', 'ResourceStatusReason', 'ResourceType', 'StackId', 'StackName' 
              @resource[name] = value
            when 'StackResourceDetail'
              @response['StackResourceDetail'] = @resource
              @resource = {}
            when 'RequestId'
              @response[name] = value
            when 'LastUpdatedTimestamp'
              @resource[name] = Time.parse(value)
            end
          end
        end
      end
    end
  end
end
