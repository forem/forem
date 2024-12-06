module Fog
  module Parsers
    module AWS
      module IAM
        class LoginProfile < Fog::Parsers::Base
          def reset
            @response = { 'LoginProfile' => {} }
          end

          def end_element(name)
            case name
            when 'UserName'
              @response['LoginProfile']['UserName'] = value
            when 'CreateDate'
              @response['LoginProfile']['CreateDate'] = Time.parse(value)
            when 'RequestId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
