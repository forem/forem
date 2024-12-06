module Fog
  module AWS
    class Lambda
      class Real
        # Returns configuration information for the specified event source mapping.
        # http://docs.aws.amazon.com/lambda/latest/dg/API_GetEventSourceMapping.html
        # ==== Parameters
        # * UUID <~String> - AWS Lambda assigned ID of the event source mapping.
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
        #     * 'Code' <~Hash> - object for the Lambda function location.
        #     * 'Configuration' <~Hash> - function metadata description.
        def get_event_source_mapping(params={})
          mapping_id = params.delete('UUID')
          request({
            :method  => 'GET',
            :path    => "/event-source-mappings/#{mapping_id}"
          }.merge(params))
        end
      end

      class Mock
        def get_event_source_mapping(params={})
          mapping_id = params.delete('UUID')

          unless mapping = self.data[:event_source_mappings][mapping_id]
            message  = 'ResourceNotFoundException => '
            message << 'The resource you requested does not exist.'
            raise Fog::AWS::Lambda::Error, message
          end

          if mapping['State'].eql?('Creating')
            mapping['LastProcessingResult'] = 'OK'
            mapping['State'] = 'Enabled'
          end

          response = Excon::Response.new
          response.status = 200
          response.body = mapping
          response
        end
      end
    end
  end
end
