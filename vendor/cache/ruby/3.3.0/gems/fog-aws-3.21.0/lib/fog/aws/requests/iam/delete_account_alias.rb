module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        def delete_account_alias(account_alias)
          request(
            'Action'    => 'DeleteAccountAlias',
            'AccountAlias' => account_alias,
            :parser     => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end
    end
  end
end
