module Fog
  module AWS
    class DNS
      class Real
        # This action deletes a health check.
        # http://docs.aws.amazon.com/Route53/latest/APIReference/API_DeleteHealthCheck.html
        #
        # ==== Parameters
        # * id<~String> - Health check ID
        # === Returns
        # * response<~Excon::Response>:
        #   * status<~Integer> - 200 when successful

        def delete_health_check(id)
          request({
            :expects => 200,
            :method  => 'DELETE',
            :path    => "healthcheck/#{id}"
          })
        end
      end
    end
  end
end
