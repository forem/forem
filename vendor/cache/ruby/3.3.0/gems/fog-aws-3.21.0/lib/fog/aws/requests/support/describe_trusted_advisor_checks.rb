module Fog
  module AWS
    class Support
      class Real
        # Describe Trusted Advisor Checks
        # http://docs.aws.amazon.com/awssupport/latest/APIReference/API_DescribeTrustedAdvisorChecks.html
        # ==== Parameters
        # * language <~String> - Language to return.  Supported values are 'en' and 'jp'
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>
        def describe_trusted_advisor_checks(options={})
          request(
            'Action'   => 'DescribeTrustedAdvisorChecks',
            'language' => options[:language] || 'en'
          )
        end
      end

      class Mock
        def describe_trusted_advisor_checks(options={})
          response = Excon::Response.new
          response.body = {'checks' => self.data[:trusted_advisor_checks].values}
          response
        end
      end
    end
  end
end
