module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/list_account_aliases'

        def list_account_aliases(options = {})
          request({
            'Action'  => 'ListAccountAliases',
            :parser   => Fog::Parsers::AWS::IAM::ListAccountAliases.new
          }.merge!(options))
        end
      end
    end
  end
end
