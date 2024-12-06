module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_dhcp_options'

        # Describe all or specified dhcp_options
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String> - Id of request
        # * 'DhcpOptionsSet'<~Array>:
        #   * 'dhcpOptionsId'<~String> - The ID of the Dhcp Options
        #   * 'dhcpConfigurationSet'<~Array>: - The list of options in the set.
        #     * 'key'<~String> - The name of a DHCP option.
        #     * 'valueSet'<~Array>: 	A set of values for a DHCP option.
        #       * 'value'<~String> - The value of a DHCP option.
        # * 'tagSet'<~Array>: Tags assigned to the resource.
        #   * 'key'<~String> - Tag's key
        #   * 'value'<~String> - Tag's value
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-ItemType-DhcpOptionsType.html]
        def describe_dhcp_options(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.warning("describe_dhcp_options with #{filters.class} param is deprecated, use dhcp_options('dhcp-options-id' => []) instead [light_black](#{caller.first})[/]")
            filters = {'dhcp-options-id' => [*filters]}
          end
          params = Fog::AWS.indexed_filters(filters)
          request({
            'Action' => 'DescribeDhcpOptions',
            :idempotent => true,
            :parser => Fog::Parsers::AWS::Compute::DescribeDhcpOptions.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_dhcp_options(filters = {})
          Excon::Response.new.tap do |response|
            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'dhcpOptionsSet'    => self.data[:dhcp_options]
            }
          end
        end
      end
    end
  end
end
