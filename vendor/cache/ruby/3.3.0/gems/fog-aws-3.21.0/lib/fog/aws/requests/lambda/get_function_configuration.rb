module Fog
  module AWS
    class Lambda
      class Real
        require 'fog/aws/parsers/lambda/base'

        # Returns the configuration information of the Lambda function.
        # http://docs.aws.amazon.com/lambda/latest/dg/API_GetFunction.html
        # ==== Parameters
        # * FunctionName <~String> - Lambda function name.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'CodeSize' <~Integer> - size, in bytes, of the function .zip file you uploaded.
        #     * 'Description' <~String> - user-provided description.
        #     * 'FunctionArn' <~String> - Amazon Resource Name (ARN) assigned to the function.
        #     * 'FunctionName' <~String> - name of the function.
        #     * 'Handler' <~String> - function Lambda calls to begin executing your function.
        #     * 'LastModified' <~Time> - timestamp of the last time you updated the function.
        #     * 'Memorysize' <~String> - memory size, in MB, you configured for the function.
        #     * 'Role' <~String> - ARN of the IAM role that Lambda assumes when it executes your function to access any other AWS resources.
        #     * 'Runtime' <~String> - runtime environment for the Lambda function.
        #     * 'Timeout' <~Integer> - function execution time at which Lambda should terminate the function.
        def get_function_configuration(params={})
          function_name = params.delete('FunctionName')
          request({
            :method  => 'GET',
            :path    => "/functions/#{function_name}/versions/HEAD/configuration",
            :parser  => Fog::AWS::Parsers::Lambda::Base.new
          }.merge(params))
        end
      end

      class Mock
        def get_function_configuration(params={})
          response = self.get_function(params)
          function_configuration = response.body['Configuration']
          response.body = function_configuration
          response
        end
      end
    end
  end
end
