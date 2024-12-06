module Fog
  module Parsers
    module AWS
      module Storage
        class GetBucketNotification < Fog::Parsers::Base
          def reset
            @func = {}
            @queue = {}
            @topic = {}
            @response = {
              'Topics' => [],
              'Queues' => [],
              'CloudFunctions' => []
            }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'TopicConfiguration'
              @configuration = 'topic'
            when 'QueueConfiguration'
              @configuration = 'queue'
            when 'CloudFunctionConfiguration'
              @configuration = 'func'
            end
          end

          def end_element(name)
            case @configuration
            when 'topic'
              case name
              when 'Id', 'Event', 'Topic'
                @topic[name] = value
              when 'TopicConfiguration'
                @response['Topics'] << @topic
                @topic = {}
              end
            when 'queue'
              case name
              when 'Id', 'Queue', 'Event'
                @queue[name] = value
              when 'QueueConfiguration'
                @response['Queues'] << @queue
                @queue = {}
              end
            when 'func'
              case name
              when 'Id', 'CloudFunction', 'InvocationRule', 'Event'
                @func[name] = value
              when 'CloudFunctionConfiguration'
                @response['CloudFunctions'] << @func
                @func = {}
              end
            end
          end
        end
      end
    end
  end
end
