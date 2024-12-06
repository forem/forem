module Fog
  module Parsers
    module AWS
      module CloudFormation
        class DescribeStackEvents < Fog::Parsers::Base
          def reset
            @event = {}
            @response = { 'StackEvents' => [] }
          end

          def end_element(name)
            case name
            when 'EventId', 'LogicalResourceId', 'PhysicalResourceId', 'ResourceProperties', 'ResourceStatus', 'ResourceStatusReason', 'ResourceType', 'StackId', 'StackName'
              @event[name] = value
            when 'member'
              @response['StackEvents'] << @event
              @event = {}
            when 'RequestId'
              @response[name] = value
            when 'Timestamp'
              @event[name] = Time.parse(value)
            end
          end
        end
      end
    end
  end
end
