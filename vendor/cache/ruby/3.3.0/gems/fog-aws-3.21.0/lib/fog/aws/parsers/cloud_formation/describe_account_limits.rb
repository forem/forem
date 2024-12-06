module Fog
  module Parsers
    module AWS
      module CloudFormation
        class DescribeAccountLimits < Fog::Parsers::Base
          def reset
            @limit = {}
            @response = { 'AccountLimits' => [] }
          end

          def end_element(name)
            case name
            when 'Name', 'Value'
              @limit[name] = value
            when 'member'
              @response['AccountLimits'] << @limit
              @limit = {}
            when 'RequestId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
