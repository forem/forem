module Fog
  module AWS
    class Lambda
      class Real
        require 'fog/aws/parsers/lambda/base'

        # Adds a permission to the access policy associated with the specified AWS Lambda function.
        # http://docs.aws.amazon.com/lambda/latest/dg/API_AddPermission.html
        # ==== Parameters
        # * FunctionName <~String> - Name of the Lambda function whose access policy you are updating by adding a new permission.
        # * Action <~String> - AWS Lambda action you want to allow in this statement.
        # * Principal <~String> - principal who is getting this permission.
        # * SourceAccount <~String> - AWS account ID (without a hyphen) of the source owner.
        # * SourceArn <~String> - Amazon Resource Name (ARN) of the source resource to assign permissions.
        # * StatemendId. <~String> - unique statement identifier.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Statement' <~Hash> - permission statement you specified in the request.
        def add_permission(params={})
          function_name  = params.delete('FunctionName')
          action         = params.delete('Action')
          principal      = params.delete('Principal')
          source_account = params.delete('SourceAccount')
          source_arn     = params.delete('SourceArn')
          sid            = params.delete('StatementId')

          permission = {
            'Action'      => action,
            'Principal'   => principal,
            'StatementId' => sid
          }
          permission['SourceAccount'] = source_account if source_account
          permission['SourceArn']     = source_arn     if source_arn

          request({
            :method  => 'POST',
            :path    => "/functions/#{function_name}/versions/HEAD/policy",
            :expects => 201,
            :body    => Fog::JSON.encode(permission),
            :parser  => Fog::AWS::Parsers::Lambda::Base.new
          }.merge(params))
        end
      end

      class Mock
        def add_permission(params={})
          function_id = params.delete('FunctionName')
          function = self.get_function_configuration(
            'FunctionName' => function_id
          ).body
          function_arn = function['FunctionArn']

          action         = params.delete('Action')
          principal      = params.delete('Principal')
          source_account = params.delete('SourceAccount')
          source_arn     = params.delete('SourceArn')
          sid            = params.delete('StatementId')

          if action.nil? || action.empty?
            message = 'Action cannot be blank'
            raise Fog::AWS::Lambda::Error, message
          end

          if principal.nil? || principal.empty?
            message = 'Principal cannot be blank'
            raise Fog::AWS::Lambda::Error, message
          end

          if sid.nil? || sid.empty?
            message = 'Sid cannot be blank'
            raise Fog::AWS::Lambda::Error, message
          end

          statement = {
            'Action'      => [action],
            'Principal'   => { 'Service' => principal },
            'Sid'         => sid,
            'Resource'    => function_arn,
            'Effect'      => 'Allow'
          }
          if source_arn
            statement['Condition'] = {}
            statement['Condition']['ArnLike'] = {
              'AWS:SourceArn' => source_arn
            }
          end

          self.data[:permissions][function_arn] ||= []
          self.data[:permissions][function_arn] << statement

          response = Excon::Response.new
          response.status = 201
          response.body = { 'Statement' => statement }
          response
        end
      end
    end
  end
end
