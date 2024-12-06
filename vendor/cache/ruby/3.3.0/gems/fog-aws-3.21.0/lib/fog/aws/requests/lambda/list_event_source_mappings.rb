module Fog
  module AWS
    class Lambda
      class Real
        # Returns a list of event source mappings where you can identify a stream as an event source.
        # http://docs.aws.amazon.com/lambda/latest/dg/API_ListEventSourceMappings.html
        # ==== Parameters
        # * EventSourceArn <~String> - Amazon Resource Name (ARN) of the stream.
        # * FunctionName <~String> - name of the Lambda function.
        # * Marker <~String> - opaque pagination token returned from a previous ListEventSourceMappings operation.
        # * MaxItems <~Integer> - maximum number of event sources to return in response.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'EventSourceMappings' <~Array> - array of EventSourceMappingConfiguration objects.
        #     * 'NextMarker' <~String> - present if there are more event source mappings.
        def list_event_source_mappings(params={})
          event_source_arn = params.delete('EventSourceArn')
          function_name    = params.delete('FunctionName')
          marker           = params.delete('Marker')
          max_items        = params.delete('MaxItems')

          query = {}
          query.merge!('EventSourceArn' => event_source_arn) if event_source_arn
          query.merge!('FunctionName'   => function_name)    if function_name
          query.merge!('Marker'         => marker)           if marker
          query.merge!('MaxItems'       => max_items)        if max_items

          request({
            :method => 'GET',
            :path   => '/event-source-mappings/',
            :query  => query
          }.merge(params))
        end
      end

      class Mock
        def list_event_source_mappings(params={})
          response = Excon::Response.new
          response.status = 200

          function_name = params.delete('FunctionName')

          begin
            function = self.get_function_configuration('FunctionName' => function_name).body
            function_arn = function['FunctionArn']
          rescue Fog::AWS::Lambda::Error => e
            # interestingly enough, if you try to do a list_event_source_mappings
            # on a nonexisting function, Lambda API endpoint doesn't return
            # error, just an empty array.
          end

          event_source_mappings = []
          if function_arn
            event_source_mappings = self.data[:event_source_mappings].values.select do |m|
              m['FunctionArn'].eql?(function_arn)
            end
          end

          response.body = {
            'EventSourceMappings' => event_source_mappings,
            'NextMarker'          => nil
          }
          response
        end
      end
    end
  end
end
