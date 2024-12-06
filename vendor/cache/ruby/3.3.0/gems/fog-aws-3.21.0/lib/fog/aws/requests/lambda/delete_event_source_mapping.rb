module Fog
  module AWS
    class Lambda
      class Real

        # Removes an event source mapping.
        # http://docs.aws.amazon.com/lambda/latest/dg/API_DeleteEventSourceMapping.html
        # ==== Parameters
        # * UUID <~String> - event source mapping ID.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~String>:
        def delete_event_source_mapping(params={})
          mapping_id = params.delete('UUID')
          request({
            :method  => 'DELETE',
            :path    => "/event-source-mappings/#{mapping_id}",
            :expects => 202
          }.merge(params))
        end
      end

      class Mock
        def delete_event_source_mapping(params={})
          mapping = self.get_event_source_mapping(params).body

          unless mapping
            message  = "ResourceNotFoundException => "
            message << "The resource you requested does not exist."
            raise Fog::AWS::Lambda::Error, message
          end

          mapping_id = mapping['UUID']
          self.data[:event_source_mappings].delete(mapping_id)

          mapping['State'] = 'Deleting'

          response = Excon::Response.new
          response.status = 202
          response.body = mapping
          response
        end
      end
    end
  end
end
