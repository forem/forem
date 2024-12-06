module Fog
  module AWS
    class Lambda
      class Real

        # Remove individual permissions from an access policy associated with a Lambda function by providing a Statement ID.
        # http://docs.aws.amazon.com/lambda/latest/dg/API_RemovePermission.html
        # ==== Parameters
        # * FunctionName <~String> - Lambda function whose access policy you want to remove a permission from.
        # * StatementId <~String> - Statement ID of the permission to remove.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~String>:
        def remove_permission(params={})
          function_name = params.delete('FunctionName')
          statement_id  = params.delete('StatementId')
          request({
            :method  => 'DELETE',
            :path    => "/functions/#{function_name}/versions/HEAD/policy/#{statement_id}",
            :expects => 204
          }.merge(params))
        end
      end

      class Mock
        def remove_permission(params={})
          function_name = params.delete('FunctionName')
          opts = { 'FunctionName' => function_name }
          function     = self.get_function_configuration(opts).body
          function_arn = function['FunctionArn']

          statement_id = params.delete('StatementId')
          message      = 'Statement ID cannot be blank'
          raise Fog::AWS::Lambda::Error, message unless statement_id

          permissions_qty = self.data[:permissions][function_arn].size

          self.data[:permissions][function_arn].delete_if do |s|
            s['Sid'].eql?(statement_id)
          end

          if self.data[:permissions][function_arn].size.eql?(permissions_qty)
            message  = "ResourceNotFoundException => "
            message << "The resource you requested does not exist."
            raise Fog::AWS::Lambda::Error, message
          end

          response        = Excon::Response.new
          response.status = 204
          response.body   =  ''
          response
        end
      end
    end
  end
end
