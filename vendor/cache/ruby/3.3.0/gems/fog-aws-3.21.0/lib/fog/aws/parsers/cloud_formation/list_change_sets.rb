module Fog
  module Parsers
    module AWS
      module CloudFormation
        class ListChangeSets < Fog::Parsers::Base
          def reset
            @change_set = {}
            @response = { 'Summaries' => [] }
          end

          def end_element(name)
            case name
            when 'ChangeSetId', 'ChangeSetName', 'Description', 'ExecutionStatus', 'StackId', 'StackName', 'Status', 'StackReason'
              @change_set[name] = value
            when 'member'
              @response['Summaries'] << @change_set
              @change_set = {}
            when 'RequestId'
              @response[name] = value
            when 'CreationTime'
              @change_set[name] = Time.parse(value)
            when 'NextToken'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
