module Fog
  module Parsers
    module AWS
      module CloudFormation
        class ListStacks < Fog::Parsers::Base
          def reset
            @stack = {}
            @response = { 'StackSummaries' => [] }
          end

          def end_element(name)
            case name
            when 'StackId', 'StackStatus', 'StackName', 'TemplateDescription'
              @stack[name] = value
            when 'member'
              @response['StackSummaries'] << @stack
              @stack = {}
            when 'RequestId'
              @response[name] = value
            when 'CreationTime'
              @stack[name] = Time.parse(value)
            when 'DeletionTime'
              @stack[name] = Time.parse(value)
            when 'NextToken'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
