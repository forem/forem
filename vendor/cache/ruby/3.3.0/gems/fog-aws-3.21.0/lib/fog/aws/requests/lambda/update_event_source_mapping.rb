module Fog
  module AWS
    class Lambda
      class Real
        # Change the parameters of the existing mapping without losing your position in the stream.
        # http://docs.aws.amazon.com/lambda/latest/dg/API_UpdateEventSourceMapping.html
        # ==== Parameters
        # * UUID <~String> - event source mapping identifier.
        # * BatchSize <~Integer> - maximum number of stream records that can be sent to your Lambda function for a single invocation.
        # * Enabled <~Boolean> - specifies whether AWS Lambda should actively poll the stream or not.
        # * FunctionName <~String> - Lambda function to which you want the stream records sent.
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
        def update_event_source_mapping(params={})
          function_name = params.delete('FunctionName')
          mapping_id    = params.delete('UUID')

          batch_size = params.delete('BatchSize')
          enabled    = params.delete('Enabled')

          update = {}
          update.merge!('BatchSize'    => batch_size)    if batch_size
          update.merge!('Enabled'      => enabled)       if !enabled.nil?
          update.merge!('FunctionName' => function_name) if function_name

          request({
            :method  => 'PUT',
            :path    => "/event-source-mappings/#{mapping_id}",
            :expects => 202,
            :body    => Fog::JSON.encode(update)
          }.merge(params))
        end
      end

      class Mock
        def update_event_source_mapping(params={})
          mapping_id = params.delete('UUID')
          mapping = self.data[:event_source_mappings][mapping_id]

          unless mapping
            message  = 'ResourceNotFoundException => '
            message << 'The resource you requested does not exist.'
            raise Fog::AWS::Lambda::Error, message
          end

          function_name = params.delete('FunctionName')
          function = {}
          if function_name
            function_opts = { 'FunctionName' => function_name }
            function      = self.get_function_configuration(function_opts).body
            function_arn  = function['FunctionArn']
          end

          batch_size = params.delete('BatchSize')
          enabled    = params.delete('Enabled')

          update = {}

          if function_name && !function.empty? && function_arn
            update.merge!('FunctionArn' => function_arn)
          end
          update.merge!('BatchSize' => batch_size) if batch_size
          update.merge!('Enabled'   => enabled)    if !enabled.nil?

          mapping.merge!(update)
          mapping['State'] = 'Disabling' if enabled.eql?(false)
          mapping['State'] = 'Enabling'  if enabled.eql?(true)

          response = Excon::Response.new
          response.status = 202
          response.body = mapping
          response
        end
      end
    end
  end
end
