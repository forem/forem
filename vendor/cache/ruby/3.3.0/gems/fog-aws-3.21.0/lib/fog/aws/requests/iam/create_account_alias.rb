module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        def create_account_alias(account_alias)
          request(
            'Action'    => 'CreateAccountAlias',
            'AccountAlias'  => account_alias,
            :parser     => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end
    end
  end
end
