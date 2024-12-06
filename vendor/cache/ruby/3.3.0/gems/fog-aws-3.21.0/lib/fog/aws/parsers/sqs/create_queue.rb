module Fog
  module Parsers
    module AWS
      module SQS
        class CreateQueue < Fog::Parsers::Base
          def reset
            @response = { 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when 'RequestId'
              @response['ResponseMetadata'][name] = @value
            when 'QueueUrl'
              @response['QueueUrl'] = @value
            end
          end
        end
      end
    end
  end
end
