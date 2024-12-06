module Fog
  module AWS
    class Lambda
      class Real
        require 'fog/aws/parsers/lambda/base'

        # Updates the code for the specified Lambda function.
        # http://docs.aws.amazon.com/lambda/latest/dg/API_UpdateFunctionCode.html
        # ==== Parameters
        # * FunctionName <~String> - existing Lambda function name whose code you want to replace.
        # * S3Bucket <~String> - Amazon S3 bucket name where the .zip file containing your deployment package is stored.
        # * S3Key <~String> - Amazon S3 object (the deployment package) key name you want to upload.
        # * S3ObjectVersion <~String> - Amazon S3 object (the deployment package) version you want to upload.
        # * ZipFile <~String> - Based64-encoded .zip file containing your packaged source code.
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
        def update_function_code(params={})
          function_name = params.delete('FunctionName')

          s3_bucket     = params.delete('S3Bucket')
          s3_key        = params.delete('S3Key')
          s3_object_ver = params.delete('S3ObjectVersion')
          zip_file      = params.delete('ZipFile')

          update = {}
          update.merge!('S3Bucket'        => s3_bucket)     if s3_bucket
          update.merge!('S3Key'           => s3_key)        if s3_key
          update.merge!('S3ObjectVersion' => s3_object_ver) if s3_object_ver
          update.merge!('ZipFile'         => zip_file)      if zip_file

          request({
            :method  => 'PUT',
            :path    => "/functions/#{function_name}/versions/HEAD/code",
            :body    => Fog::JSON.encode(update),
            :parser  => Fog::AWS::Parsers::Lambda::Base.new
          }.merge(params))
        end
      end

      class Mock
        def update_function_code(params={})
          response = self.get_function_configuration(params)

          request_data = []
          %w(S3Bucket S3Key S3ObjectVersion ZipFile).each do |p|
            request_data << params.delete(p) if params.has_key?(p)
          end

          message = 'Please provide a source for function code.'
          raise Fog::AWS::Lambda::Error, message if request_data.empty?
          # we ignore any parameters since we are not uploading any code

          function_arn = response.body['FunctionArn']

          response = Excon::Response.new
          response.status = 200
          response.body = self.data[:functions][function_arn]

          response
        end
      end
    end
  end
end
