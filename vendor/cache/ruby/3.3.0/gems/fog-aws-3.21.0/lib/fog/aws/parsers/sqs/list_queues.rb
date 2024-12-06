module Fog
  module Parsers
    module AWS
      module SQS
        class ListQueues < Fog::Parsers::Base
          def reset
            @response = { 'QueueUrls' => [], 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when 'RequestId'
              @response['ResponseMetadata'][name] = @value
            when 'QueueUrl'
              @response['QueueUrls'] << @value
            end
          end
        end
      end
    end
  end
end
