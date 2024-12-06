module Fog
  module AWS
    class DNS
      class Real
        require 'fog/aws/parsers/dns/health_check'

        # This action gets information about a specified health check.
        #http://docs.aws.amazon.com/Route53/latest/APIReference/API_GetHealthCheck.html
        #
        # ==== Parameters
        # * id<~String> - The ID of the health check
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'HealthCheck'<~Hash>:
        #       * 'Id'<~String> -
        #       * 'CallerReference'<~String>
        #       * 'HealthCheckConfig'<~Hash>:
        #         * 'IPAddress'<~String> -
        #         * 'Port'<~String> -
        #         * 'Type'<~String> -
        #         * 'ResourcePath'<~String> -
        #         * 'FullyQualifiedDomainName'<~String> -
        #         * 'SearchString'<~String> -
        #         * 'RequestInterval'<~Integer> -
        #         * 'FailureThreshold'<~String> -
        #       * 'HealthCheckVersion'<~Integer> -
        #   * status<~Integer> - 200 when successful
        def get_health_check(id)
          request({
            :expects => 200,
            :parser  => Fog::Parsers::AWS::DNS::HealthCheck.new,
            :method  => 'GET',
            :path    => "healthcheck/#{id}"
          })
        end
      end
    end
  end
end
