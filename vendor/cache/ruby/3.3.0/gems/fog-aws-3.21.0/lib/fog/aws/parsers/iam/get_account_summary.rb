module Fog
  module Parsers
    module AWS
      module IAM
        class GetAccountSummary < Fog::Parsers::Base
          def reset
            super
            @stack = []
            @response = {'Summary' => {}}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'SummaryMap'
              @stack << name
            end
          end

          def end_element(name)
            case name
            when 'SummaryMap'
              @stack.pop
            when 'key'
              if @stack.last == 'SummaryMap'
                @key = value
              end
            when 'value'
              if @stack.last == 'SummaryMap'
                @response['Summary'][@key] = value.strip.to_i
              end
            when 'RequestId'
              if @stack.empty?
                @response['RequestId'] = value.strip
              end
            end
          end
        end
      end
    end
  end
end
