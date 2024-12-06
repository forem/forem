module Fog
  module AWS
    class Lambda
      class Real

        # Deletes the specified Lambda function code and configuration.
        # http://docs.aws.amazon.com/lambda/latest/dg/API_DeleteFunction.html
        # ==== Parameters
        # * FunctionName <~String> - Lambda function to delete.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~String>:
        def delete_function(params={})
          function_name = params.delete('FunctionName')
          request({
            :method  => 'DELETE',
            :path    => "/functions/#{function_name}",
            :expects => 204
          }.merge(params))
        end
      end

      class Mock
        def delete_function(params={})
          response = Excon::Response.new
          response.status = 204
          response.body = ''

          function = self.get_function_configuration(params).body
          function_id = function['FunctionArn']

          self.data[:functions].delete function_id
          self.data[:permissions].delete function_id
          self.data[:event_source_mappings].delete_if do |m,f|
            f['FunctionArn'].eql?(function_id)
          end

          response
        end
      end
    end
  end
end
