module Fog
  module Parsers
    module AWS
      module SNS
        class GetTopicAttributes < Fog::Parsers::Base
          def reset
            @response = { 'Attributes' => {} }
          end

          def end_element(name)
            case name
            when 'key'
              @key = @value.rstrip
            when 'value'
              case @key
              when 'SubscriptionsConfirmed', 'SubscriptionsDeleted', 'SubscriptionsPending'
                @response['Attributes'][@key] = @value.rstrip.to_i
              else
                @response['Attributes'][@key] = (@value && @value.rstrip) || nil
              end
            when 'RequestId'
              @response[name] = @value.rstrip
            end
          end
        end
      end
    end
  end
end
