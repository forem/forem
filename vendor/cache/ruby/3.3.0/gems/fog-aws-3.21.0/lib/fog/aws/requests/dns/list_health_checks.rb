module Fog
  module AWS
    class DNS
      class Real
        require 'fog/aws/parsers/dns/list_health_checks'

        # This action gets a list of the health checks that are associated with the current AWS account.
        # http://docs.aws.amazon.com/Route53/latest/APIReference/API_ListHealthChecks.html
        #
        # === Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'HealthChecks'<~Array>:
        #       * 'HealthCheck'<~Hash>:
        #         * 'Id'<~String> -
        #         * 'CallerReference'<~String>
        #         * 'HealthCheckVersion'<~Integer> -
        #     * 'Marker'<~String> -
        #     * 'MaxItems'<~Integer> -
        #     * 'IsTruncated'<~String> -
        #     * 'NextMarker'<~String>
        #   * status<~Integer> - 200 when successful

        def list_health_checks
          request({
            :expects => 200,
            :method  => 'GET',
            :path    => "healthcheck",
            :parser  => Fog::Parsers::AWS::DNS::ListHealthChecks.new
          })
        end
      end
    end
  end
end

