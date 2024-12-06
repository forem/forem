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
        #     * 'Code' <~Hash> - object for the Lambda function location.
        #     * 'Configuration' <~Hash> - function metadata description.
        def get_function(params={})
          function_name = params.delete('FunctionName')
          request({
            :method  => 'GET',
            :path    => "/functions/#{function_name}/versions/HEAD",
            :parser  => Fog::AWS::Parsers::Lambda::Base.new
          }.merge(params))
        end
      end

      class Mock
        def get_function(params={})
          response = Excon::Response.new
          response.status = 200
          response.body = ''

          unless function_id = params.delete('FunctionName')
            raise Fog::AWS::Lambda::Error, 'Function name cannot be blank.'
          end

          if function_id.match(/^arn:aws:lambda:.+:function:.+/)
            function = self.data[:functions][function_id]
          else
            search_function = Hash[
              self.data[:functions].select do |f,v|
                v['FunctionName'].eql?(function_id)
              end
            ]
            function = search_function.values.first
          end

          msg = 'The resource you requested does not exist.'
          raise Fog::AWS::Lambda::Error, msg if (function.nil? || function.empty?)

          location = "https://awslambda-#{self.region}-tasks.s3-#{self.region}"
          location << ".amazonaws.com/snapshot/#{self.account_id}/"
          location << "#{function['FunctionName']}-#{UUID.uuid}"
          location << '?x-amz-security-token='
          location << Fog::Mock.random_base64(718)
          location << "&AWSAccessKeyId=#{self.aws_access_key_id}"
          location << "&Expires=#{Time.now.to_i + 60*10}"
          location << '&Signature='
          location << Fog::Mock.random_base64(28)

          body = {
            'Code' => {
              'Location'       => location,
              'RepositoryType' => 'S3'
            },
            'Configuration' => function
          }
          response.body = body

          response
        end
      end
    end
  end
end
