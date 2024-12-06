module Fog
  module AWS
    class Lambda
      class Real
        # Identifies a stream as an event source for a Lambda function.
        # http://docs.aws.amazon.com/lambda/latest/dg/API_CreateEventSourceMapping.html
        # ==== Parameters
        # * BatchSize <~Integer> - largest number of records that AWS Lambda will retrieve from your event source at the time of invoking your function.
        # * Enabled <~Boolean> - indicates whether AWS Lambda should begin polling the event source.
        # * EventSourceArn <~String> - Amazon Resource Name (ARN) of the stream that is the event source
        # * FunctionName <~String> - Lambda function to invoke when AWS Lambda detects an event on the stream.
        # * StartingPosition <~String> - position in the stream where AWS Lambda should start reading.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'BatchSize' <~Integer> - largest number of records that AWS Lambda will retrieve from your event source at the time of invoking your function.
        #     * 'EventSourceArn' <~String> - Amazon Resource Name (ARN) of the stream that is the source of events.
        #     * 'FunctionArn' <~String> - Lambda function to invoke when AWS Lambda detects an event on the stream.
        #     * 'LastModified' <~Time> - UTC time string indicating the last time the event mapping was updated.
        #     * 'LastProcessingResult' <~String> - result of the last AWS Lambda invocation of your Lambda function.
        #     * 'State' <~String> - state of the event source mapping.
        #     * 'StateTransitionReason' <~String> - reason the event source mapping is in its current state.
        #     * 'UUID' <~String> - AWS Lambda assigned opaque identifier for the mapping.
        def create_event_source_mapping(params={})
          enabled          = params.delete('Enabled')
          batch_size       = params.delete('BatchSize')
          event_source_arn = params.delete('EventSourceArn')
          function_name    = params.delete('FunctionName')
          starting_pos     = params.delete('StartingPosition')

          data = {
            'EventSourceArn'   => event_source_arn,
            'FunctionName'     => function_name,
            'StartingPosition' => starting_pos
          }
          data.merge!('BatchSize' => batch_size) if batch_size
          data.merge!('Enabled'   => enabled)    if !enabled.nil?

          request({
            :method  => 'POST',
            :path    => '/event-source-mappings/',
            :expects => 202,
            :body    => Fog::JSON.encode(data)
          }.merge(params))
        end
      end

      class Mock
        def create_event_source_mapping(params={})
          enabled          = params.delete('Enabled')   || false
          batch_size       = params.delete('BatchSize') || 100
          event_source_arn = params.delete('EventSourceArn')
          function_name    = params.delete('FunctionName')
          starting_pos     = params.delete('StartingPosition')

          function = self.get_function_configuration('FunctionName' => function_name).body

          unless event_source_arn
            message  = "ValidationException => "
            message << "'eventSourceArn' cannot be blank"
            raise Fog::AWS::Lambda::Error, message
          end

          unless starting_pos
            message  = "ValidationException => "
            message << "'startingPosition' cannot be blank"
            raise Fog::AWS::Lambda::Error, message
          end

          event_source_mapping_id = UUID.uuid
          event_source_mapping = {
            'BatchSize'             => batch_size,
            'EventSourceArn'        => event_source_arn,
            'FunctionArn'           => function['FunctionArn'],
            'LastModified'          => Time.now.to_f,
            'LastProcessingResult'  => 'No records processed',
            'State'                 => 'Creating',
            'StateTransitionReason' => 'User action',
            'UUID'                  => event_source_mapping_id
          }

          self.data[:event_source_mappings].merge!(
            event_source_mapping_id => event_source_mapping
          )

          response = Excon::Response.new
          response.body = event_source_mapping
          response.status = 202
          response
        end
      end
    end
  end
end
