module Fog
  module AWS
    class Lambda
      class Real
        require 'fog/aws/parsers/lambda/base'

        # Creates a new Lambda function.
        # http://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html
        # ==== Parameters
        # * Code <~Hash> - code for the Lambda function.
        # * Description <~String> - short, user-defined function description.
        # * FunctionName <~String> - name you want to assign to the function you are uploading.
        # * Handler <~String> - function within your code that Lambda calls to begin execution.
        # * MemorySize <~Integer> - amount of memory, in MB, your Lambda function is given.
        # * Role <~String> - ARN of the IAM role that Lambda assumes when it executes your function to access any other AWS resources.
        # * Runtime <~String> - runtime environment for the Lambda function you are uploading.
        # * Timeout <~Integer> - function execution time at which Lambda should terminate the function.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'CodeSize' <~Integer> - size, in bytes, of the function .zip file you uploaded.
        #     * 'Description' <~String> - user-provided description.
        #     * 'FunctionArn' <~String> - Amazon Resource Name (ARN) assigned to the function.
        #     * 'FunctionName' <~String> - name of the function.
        #     * 'Handler' <~String> - function Lambda calls to begin executing your function.
        #     * 'LastModified' <~Time> - timestamp of the last time you updated the function.
        #     * 'MemorySize' <~Integer> - memory size, in MB, you configured for the function.
        #     * 'Role' <~String> - ARN of the IAM role that Lambda assumes when it executes your function to access any other AWS resources.
        #     * 'Runtime' <~String> - runtime environment for the Lambda function.
        #     * 'Timeout' <~Integer> - function execution time at which Lambda should terminate the function.
        def create_function(params={})
          runtime       = params.delete('Runtime') || 'nodejs'
          code          = params.delete('Code')
          function_name = params.delete('FunctionName')
          handler       = params.delete('Handler')
          role          = params.delete('Role')

          data = {
            'Runtime'      => runtime,
            'Code'         => code,
            'FunctionName' => function_name,
            'Handler'      => handler,
            'Role'         => role
          }

          description = params.delete('Description')
          data.merge!('Description' => description) if description

          memory_size = params.delete('MemorySize')
          data.merge!('MemorySize' => memory_size)  if memory_size

          timeout = params.delete('Timeout')
          data.merge!('Timeout' => timeout) if timeout

          request({
            :method  => 'POST',
            :path    => '/functions',
            :expects => 201,
            :body    => Fog::JSON.encode(data),
            :parser  => Fog::AWS::Parsers::Lambda::Base.new
          }.merge(params))
        end
      end

      class Mock
        def create_function(params={})
          response = Excon::Response.new

          runtime = params.delete('Runtime') || 'nodejs'
          if !%w(nodejs java8).include?(runtime)
            message = 'ValidationException: Runtime must be nodejs or java8.'
            raise Fog::AWS::Lambda::Error, message
          end

          unless code = params.delete('Code')
            message = 'ValidationException: Code cannot be blank.'
            raise Fog::AWS::Lambda::Error, message
          end

          unless function_name = params.delete('FunctionName')
            message = 'ValidationException: Function name cannot be blank.'
            raise Fog::AWS::Lambda::Error, message
          end

          unless handler = params.delete('Handler')
            message = 'ValidationException: Handler cannot be blank.'
            raise Fog::AWS::Lambda::Error, message
          end

          unless role = params.delete('Role')
            message = 'ValidationException: Role cannot be blank.'
            raise Fog::AWS::Lambda::Error, message
          end

          code_size = if code.has_key?('ZipFile')
            Base64.decode64(code['ZipFile']).length
          else
            Fog::Mock.random_numbers(5).to_i
          end

          description = params.delete('Description')

          function = {}
          begin
            opts     = { 'FunctionName' => function_name }
            function = self.get_function_configuration(opts).body
          rescue Fog::AWS::Lambda::Error => e
            # ignore: if the function doesn't exist we are OK.
          end

          if !function.empty?
            message  = "ResourceConflictException => "
            message << "Function already exist: #{function_name}"
            raise Fog::AWS::Lambda::Error, message
          end

          function_path = "function:#{function_name}"
          function_arn = Fog::AWS::Mock.arn(
            'lambda',
            self.account_id,
            function_path,
            self.region
          )

          function = {
            'CodeSize'     => code_size,
            'FunctionArn'  => function_arn,
            'FunctionName' => function_name,
            'Handler'      => handler,
            'LastModified' => Time.now.utc,
            'MemorySize'   => params.delete('MemorySize') || 128,
            'Timeout'      => params.delete('Timeout')    || 3,
            'Role'         => role,
            'Runtime'      => runtime
          }
          function['Description'] = description if description

          self.data[:functions][function_arn] = function
          response.body   = function
          response.status = 200
          response
        end
      end
    end
  end
end
