module Fog
  module Parsers
    module AWS
      module CloudFormation
        class ListStackResources < Fog::Parsers::Base
          def reset
            @resource = {}
            @response = { 'StackResourceSummaries' => [] }
          end

          def end_element(name)
            case name
            when 'ResourceStatus', 'LogicalResourceId', 'PhysicalResourceId', 'ResourceType'
              @resource[name] = value
            when 'member'
              @response['StackResourceSummaries'] << @resource
              @resource = {}
            when 'LastUpdatedTimestamp'
              @resource[name] = Time.parse(value)
            when 'RequestId'
              @response[name] = value
            when 'NextToken'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
