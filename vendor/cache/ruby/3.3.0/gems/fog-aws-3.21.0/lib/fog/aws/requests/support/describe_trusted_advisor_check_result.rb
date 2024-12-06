module Fog
  module AWS
    class Support
      class Real
        # Describe Trusted Advisor Check Result
        # http://docs.aws.amazon.com/awssupport/latest/APIReference/API_DescribeTrustedAdvisorCheckResult.html
        # ==== Parameters
        # * checkId <~String>  - Id of the check obtained from #describe_trusted_advisor_checks
        # * language <~String> - Language to return.  Supported values are 'en' and 'jp'
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>
        def describe_trusted_advisor_check_result(options={})
          request(
            'Action'   => 'DescribeTrustedAdvisorCheckResult',
            'checkId'  => options[:id],
            'language' => options[:language] || 'en'
          )
        end
      end

      class Mock
        def describe_trusted_advisor_check_result(options={})
          response = Excon::Response.new
          response.body = {'result' => self.data[:trusted_advisor_check_results][options[:id]]}
          response
        end
      end
    end
  end
end
