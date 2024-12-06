module Fog
  module AWS
    class DNS
      class Real
        require 'fog/aws/parsers/dns/health_check'

        # This action creates a new health check.
        # http://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateHealthCheck.html
        #
        # ==== Parameters (options as symbols Hash)
        # * ip_address<~String> - (optional if fqdn) The IPv4 IP address of the endpoint on which you want Amazon Route 53 to perform health checks
        # * port<~Integer> - The port on the endpoint on which you want Amazon Route 53 to perform health checks
        # * type<~String> - HTTP | HTTPS | HTTP_STR_MATCH | HTTPS_STR_MATCH | TCP
        # * resource_path<~Stringy> - (required for all types except TCP) The path that you want Amazon Route 53 to request when performing health checks. The path can be any value for which your endpoint will return an HTTP status code of 2xx or 3xx when the endpoint is healthy
        # * fqdn<~String> - (optional if ip_address) The value that you want Amazon Route 53 to pass in the Host header in all health checks except TCP health checks
        # * search_string<~String> - If the value of Type is HTTP_STR_MATCH or HTTP_STR_MATCH, the string that you want Amazon Route 53 to search for in the response body from the specified resource
        # * request_interval<~String> - 10 | 30 (optional) The number of seconds between the time that Amazon Route 53 gets a response from your endpoint and the time that it sends the next health-check request
        # * failure_threshold<~Integer> - 1-10 (optional) The number of consecutive health checks that an endpoint must pass or fail for Amazon Route 53 to change the current status of the endpoint from unhealthy to healthy or vice versa
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'HealthCheck'<~Hash>
        #       * 'Id'<~String> - The ID of the request
        #       * 'CallerReference'<~String> - A unique string that identifies the request and that allows failed CreateHealthCheck requests to be retried without the risk of executing the operation twice.
        #       * 'HealthCheckConfig'<~Hash>
        #         * 'IPAddress'
        #         * 'Port'
        #         * 'Type'
        #         * 'ResourcePath'
        #         * 'FullyQualifiedDomainName'
        #         * 'RequestInterval'
        #         * 'FailureThreshold'
        #   * status<~Integer> - 201 when successful

        def create_health_check(ip_address, port, type, options = {})
          version = @version
          builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
            xml.CreateHealthCheckRequest(:xmlns => "https://route53.amazonaws.com/doc/#{version}/") do
              xml.CallerReference options[:caller_reference] || "#{Time.now.to_i.to_s}-#{SecureRandom.hex(6)}"
              xml.HealthCheckConfig do
                xml.IPAddress ip_address unless ip_address.nil?
                xml.Port port
                xml.Type type
                xml.ResourcePath options[:resource_path] if options.has_key?(:resource_path)
                xml.FullyQualifiedDomainName options[:fqdn] if options.has_key?(:fqdn)
                xml.SearchString options[:search_string] if options.has_key?(:search_string)
                xml.RequestInterval options[:request_interval] if options.has_key?(:request_interval)
                xml.FailureThreshold options[:failure_threshold] if options.has_key?(:failure_threshold)
              end
            end
          end

          request({
            :body    => builder.to_xml.to_s,
            :expects => 201,
            :method  => 'POST',
            :path    => 'healthcheck',
            :parser  => Fog::Parsers::AWS::DNS::HealthCheck.new
          })
        end
      end
    end
  end
end
