module Fog
  module AWS
    class Lambda
      class Real

        # Invokes a specified Lambda function.
        # http://docs.aws.amazon.com/lambda/latest/dg/API_Invoke.html
        # ==== Parameters
        # * ClientContext <~Hash> - client-specific information to the Lambda function you are invoking.
        # * FunctionName <~String> - Lambda function name.
        # * InvocationType <~String> - function invocation type.
        # * LogType <~String> - logs format for function calls of "RequestResponse" invocation type.
        # * Payload <~Integer> - Lambda function input.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash> - JSON representation of the object returned by the Lambda function.
        def invoke(params={})
          headers = {}
          if client_context = params.delete('ClientContext')
            headers['X-Amz-Client-Context'] =
              Base64::encode64(Fog::JSON.encode(client_context))
          end
          if invocation_type = params.delete('InvocationType')
            headers['X-Amz-Invocation-Type'] = invocation_type
          end
          if log_type = params.delete('LogType')
            headers['X-Amz-Log-Type'] = log_type
          end
          payload = Fog::JSON.encode(params.delete('Payload'))
          function_name = params.delete('FunctionName')

          request({
            :method  => 'POST',
            :path    => "/functions/#{function_name}/invocations",
            :headers => headers,
            :body    => payload,
            :expects => [200, 202, 204]
          }.merge(params))
        end
      end

      class Mock
        def invoke(params={})
          response = Excon::Response.new
          response.status = 200
          response.body = ''

          unless function_id = params.delete('FunctionName')
            message = 'AccessDeniedException => '
            message << 'Unable to determine service/operation name to be authorized'
            raise Fog::AWS::Lambda::Error, message
          end

          client_context  = params.delete('ClientContext')
          invocation_type = params.delete('InvocationType')
          log_type        = params.delete('LogType')
          payload         = params.delete('Payload')

          if (client_context || invocation_type || log_type)
            message = "invoke parameters handling are not yet mocked [light_black](#{caller.first})[/]"
            Fog::Logger.warning message
            Fog::Mock.not_implemented
          end

          if payload
            message = "payload parameter is ignored since we are not really "
            message << "invoking a function [light_black](#{caller.first})[/]"
            Fog::Logger.warning message
          end

          function = self.get_function_configuration('FunctionName' => function_id).body

          if function.is_a?(Hash) && function.has_key?('FunctionArn')
            response.body = "\"Imagine #{function['FunctionArn']} was invoked\""
          else
            message = "ResourceNotFoundException => Function not found: #{function_id}"
            raise Fog::AWS::Lambda::Error, message
          end

          response
        end
      end
    end
  end
end
