require 'fog/aws/models/support/trusted_advisor_check'

module Fog
  module AWS
    class Support
      class TrustedAdvisorChecks < Fog::Collection
        model Fog::AWS::Support::TrustedAdvisorCheck

        def all
          data = service.describe_trusted_advisor_checks.body['checks']
          load(data)
        end

        def get(id)
          data = service.describe_trusted_advisor_check_result(:id => id).body['result']
          new(data).populate_extended_attributes
        end
      end
    end
  end
end
