module Fog
  module AWS
    class Lambda
      class Real
        require 'fog/aws/parsers/lambda/base'

        # Updates the configuration parameters for the specified Lambda function.
        # http://docs.aws.amazon.com/lambda/latest/dg/API_UpdateFunctionConfiguration.html
        # ==== Parameters
        # * FunctionName <~String> - name of the Lambda function.
        # * Description <~String> - short user-defined function description.
        # * Handler <~String> - function that Lambda calls to begin executing your function.
        # * MemorySize <~Integer> - amount of memory, in MB, your Lambda function is given.
        # * Role <~String> - ARN of the IAM role that Lambda will assume when it executes your function.
        # * Timeout <~Integer> - function execution time at which AWS Lambda should terminate the function.
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
        def update_function_configuration(params={})
          function_name = params.delete('FunctionName')

          description = params.delete('Description')
          handler     = params.delete('Handler')
          memory_size = params.delete('MemorySize')
          role        = params.delete('Role')
          timeout     = params.delete('Timeout')

          update = {}
          update.merge!('Description' => description) if description
          update.merge!('Handler'     => handler)     if handler
          update.merge!('MemorySize'  => memory_size) if memory_size
          update.merge!('Role'        => role)        if role
          update.merge!('Timeout'     => timeout)     if timeout

          request({
            :method  => 'PUT',
            :path    => "/functions/#{function_name}/versions/HEAD/configuration",
            :body    => Fog::JSON.encode(update),
            :parser  => Fog::AWS::Parsers::Lambda::Base.new
          }.merge(params))
        end
      end

      class Mock
        def update_function_configuration(params={})
          response = self.get_function_configuration(params)

          function_arn = response.body['FunctionArn']

          description = params.delete('Description')
          handler     = params.delete('Handler')
          memory_size = params.delete('MemorySize')
          role        = params.delete('Role')
          timeout     = params.delete('Timeout')

          update = {}
          update.merge!('Description' => description) if description
          update.merge!('Handler'     => handler)     if handler
          update.merge!('MemorySize'  => memory_size) if memory_size
          update.merge!('Role'        => role)        if role
          update.merge!('Timeout'     => timeout)     if timeout

          self.data[:functions][function_arn].merge!(update)

          response = Excon::Response.new
          response.status = 200
          response.body = self.data[:functions][function_arn]

          response
        end
      end
    end
  end
end
