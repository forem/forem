module Fog
  module AWS
    class Lambda
      class Real
        require 'fog/aws/parsers/lambda/base'

        # Returns the access policy, containing a list of permissions granted via the AddPermission API, associated with the specified bucket.
        # http://docs.aws.amazon.com/lambda/latest/dg/API_GetPolicy.html
        # ==== Parameters
        # * FunctionName <~String> - Function name whose access policy you want to retrieve.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Policy' <~Hash> - The access policy associated with the specified function.
        def get_policy(params={})
          function_name = params.delete('FunctionName')
          request({
            :method  => 'GET',
            :path    => "/functions/#{function_name}/versions/HEAD/policy",
            :parser => Fog::AWS::Parsers::Lambda::Base.new
          }.merge(params))
        end
      end

      class Mock
        def get_policy(params={})
          response = Excon::Response.new

          function     = self.get_function_configuration(params).body
          function_arn = function['FunctionArn']
          statements   = self.data[:permissions][function_arn] || []

          if statements.empty?
            message = "ResourceNotFoundException => "
            message << "The resource you requested does not exist."
            raise Fog::AWS::Lambda::Error, message
          end

          policy = {
            'Version'   => '2012-10-17',
            'Statement' => statements,
            'Id'        => 'default'
          }

          response.status = 200
          response.body = { 'Policy' => policy }
          response
        end
      end
    end
  end
end
